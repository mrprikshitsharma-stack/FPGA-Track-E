// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2023.2 (64-bit)
// Tool Version Limit: 2023.10
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
#ifndef XPASSTHROUGH_STREAM_H
#define XPASSTHROUGH_STREAM_H

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/
#ifndef __linux__
#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"
#include "xil_io.h"
#else
#include <stdint.h>
#include <assert.h>
#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stddef.h>
#endif
#include "xpassthrough_stream_hw.h"

/**************************** Type Definitions ******************************/
#ifdef __linux__
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
#else
typedef struct {
#ifdef SDT
    char *Name;
#else
    u16 DeviceId;
#endif
    u64 Ctrl_BaseAddress;
} XPassthrough_stream_Config;
#endif

typedef struct {
    u64 Ctrl_BaseAddress;
    u32 IsReady;
} XPassthrough_stream;

typedef u32 word_type;

/***************** Macros (Inline Functions) Definitions *********************/
#ifndef __linux__
#define XPassthrough_stream_WriteReg(BaseAddress, RegOffset, Data) \
    Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))
#define XPassthrough_stream_ReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))
#else
#define XPassthrough_stream_WriteReg(BaseAddress, RegOffset, Data) \
    *(volatile u32*)((BaseAddress) + (RegOffset)) = (u32)(Data)
#define XPassthrough_stream_ReadReg(BaseAddress, RegOffset) \
    *(volatile u32*)((BaseAddress) + (RegOffset))

#define Xil_AssertVoid(expr)    assert(expr)
#define Xil_AssertNonvoid(expr) assert(expr)

#define XST_SUCCESS             0
#define XST_DEVICE_NOT_FOUND    2
#define XST_OPEN_DEVICE_FAILED  3
#define XIL_COMPONENT_IS_READY  1
#endif

/************************** Function Prototypes *****************************/
#ifndef __linux__
#ifdef SDT
int XPassthrough_stream_Initialize(XPassthrough_stream *InstancePtr, UINTPTR BaseAddress);
XPassthrough_stream_Config* XPassthrough_stream_LookupConfig(UINTPTR BaseAddress);
#else
int XPassthrough_stream_Initialize(XPassthrough_stream *InstancePtr, u16 DeviceId);
XPassthrough_stream_Config* XPassthrough_stream_LookupConfig(u16 DeviceId);
#endif
int XPassthrough_stream_CfgInitialize(XPassthrough_stream *InstancePtr, XPassthrough_stream_Config *ConfigPtr);
#else
int XPassthrough_stream_Initialize(XPassthrough_stream *InstancePtr, const char* InstanceName);
int XPassthrough_stream_Release(XPassthrough_stream *InstancePtr);
#endif

void XPassthrough_stream_Start(XPassthrough_stream *InstancePtr);
u32 XPassthrough_stream_IsDone(XPassthrough_stream *InstancePtr);
u32 XPassthrough_stream_IsIdle(XPassthrough_stream *InstancePtr);
u32 XPassthrough_stream_IsReady(XPassthrough_stream *InstancePtr);
void XPassthrough_stream_EnableAutoRestart(XPassthrough_stream *InstancePtr);
void XPassthrough_stream_DisableAutoRestart(XPassthrough_stream *InstancePtr);

void XPassthrough_stream_Set_n_samples(XPassthrough_stream *InstancePtr, u32 Data);
u32 XPassthrough_stream_Get_n_samples(XPassthrough_stream *InstancePtr);

void XPassthrough_stream_InterruptGlobalEnable(XPassthrough_stream *InstancePtr);
void XPassthrough_stream_InterruptGlobalDisable(XPassthrough_stream *InstancePtr);
void XPassthrough_stream_InterruptEnable(XPassthrough_stream *InstancePtr, u32 Mask);
void XPassthrough_stream_InterruptDisable(XPassthrough_stream *InstancePtr, u32 Mask);
void XPassthrough_stream_InterruptClear(XPassthrough_stream *InstancePtr, u32 Mask);
u32 XPassthrough_stream_InterruptGetEnabled(XPassthrough_stream *InstancePtr);
u32 XPassthrough_stream_InterruptGetStatus(XPassthrough_stream *InstancePtr);

#ifdef __cplusplus
}
#endif

#endif
