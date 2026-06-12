// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2023.2 (64-bit)
// Tool Version Limit: 2023.10
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
#ifndef __linux__

#include "xstatus.h"
#ifdef SDT
#include "xparameters.h"
#endif
#include "xpassthrough_stream.h"

extern XPassthrough_stream_Config XPassthrough_stream_ConfigTable[];

#ifdef SDT
XPassthrough_stream_Config *XPassthrough_stream_LookupConfig(UINTPTR BaseAddress) {
	XPassthrough_stream_Config *ConfigPtr = NULL;

	int Index;

	for (Index = (u32)0x0; XPassthrough_stream_ConfigTable[Index].Name != NULL; Index++) {
		if (!BaseAddress || XPassthrough_stream_ConfigTable[Index].Ctrl_BaseAddress == BaseAddress) {
			ConfigPtr = &XPassthrough_stream_ConfigTable[Index];
			break;
		}
	}

	return ConfigPtr;
}

int XPassthrough_stream_Initialize(XPassthrough_stream *InstancePtr, UINTPTR BaseAddress) {
	XPassthrough_stream_Config *ConfigPtr;

	Xil_AssertNonvoid(InstancePtr != NULL);

	ConfigPtr = XPassthrough_stream_LookupConfig(BaseAddress);
	if (ConfigPtr == NULL) {
		InstancePtr->IsReady = 0;
		return (XST_DEVICE_NOT_FOUND);
	}

	return XPassthrough_stream_CfgInitialize(InstancePtr, ConfigPtr);
}
#else
XPassthrough_stream_Config *XPassthrough_stream_LookupConfig(u16 DeviceId) {
	XPassthrough_stream_Config *ConfigPtr = NULL;

	int Index;

	for (Index = 0; Index < XPAR_XPASSTHROUGH_STREAM_NUM_INSTANCES; Index++) {
		if (XPassthrough_stream_ConfigTable[Index].DeviceId == DeviceId) {
			ConfigPtr = &XPassthrough_stream_ConfigTable[Index];
			break;
		}
	}

	return ConfigPtr;
}

int XPassthrough_stream_Initialize(XPassthrough_stream *InstancePtr, u16 DeviceId) {
	XPassthrough_stream_Config *ConfigPtr;

	Xil_AssertNonvoid(InstancePtr != NULL);

	ConfigPtr = XPassthrough_stream_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {
		InstancePtr->IsReady = 0;
		return (XST_DEVICE_NOT_FOUND);
	}

	return XPassthrough_stream_CfgInitialize(InstancePtr, ConfigPtr);
}
#endif

#endif

