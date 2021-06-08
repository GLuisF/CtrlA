###############################################################################
# Makefile for project 
###############################################################################

## General options
PROJECT = 
MCU = AT89C52
COMPILER = "ASEM-51 (Proteus)"
TARGET = Debug
CLOCK = 11059200
SHELL = C:\Windows\system32\cmd.exe

## Tools general options

## Processing Tools
ASM=asem.exe
DDX=ASEMDDX.EXE
#  C:/Giovani/CtrlA/Debug/Debug.HEX: TOOL=ASM
#  Post: $(DDX) $(DDXFLAGS) Debug.lst
#  Post: "D:\Program Files (x86)\Labcenter Electronics\VSM Studio for Proteus 7\BIN\mv" "Debug.SDI" "Debug/Debug.SDI"
#     C:/Giovani/CtrlA/CtrlA.ASM

# Build tree:
all:	Debug

Debug:	Debug/Debug.HEX

Debug/Debug.HEX:	CtrlA.ASM 
	$(ASM) "CtrlA.ASM" "Debug\Debug.HEX" Debug.lst $(ASMFLAGS)  /INCLUDES:"D:\Program Files (x86)\Labcenter Electronics\Proteus 7 Professional\tools\ASEM51"
	$(DDX) $(DDXFLAGS) Debug.lst
	"D:\Program Files (x86)\Labcenter Electronics\VSM Studio for Proteus 7\BIN\mv" "Debug.SDI" "Debug/Debug.SDI"

# tidy - delete all temporary files which are not involved in the target generation
tidy:
	rm -rf Debug.lst
	rm -rf Debug/Debug.SDI

# cleanup - delete all generated files
clean:	tidy
	rm -rf Debug/Debug.HEX
