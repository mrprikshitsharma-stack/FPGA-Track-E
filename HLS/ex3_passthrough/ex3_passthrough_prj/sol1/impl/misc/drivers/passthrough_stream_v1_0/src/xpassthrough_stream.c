// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2023.2 (64-bit)
// Tool Version Limit: 2023.10
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
/***************************** Include Files *********************************/
#include "xpassthrough_stream.h"

/************************** Function Implementation *************************/
#ifndef __linux__
int XPassthrough_stream_CfgInitialize(XPassthrough_stream *InstancePtr, XPassthrough_stream_Config *ConfigPtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(ConfigPtr != NULL);

    InstancePtr->Ctrl_BaseAddress = ConfigPtr->Ctrl_BaseAddress;
    InstancePtr->IsReady = XIL_COMPONENT_IS_READY;

    return XST_SUCCESS;
}
#endif

void XPassthrough_stream_Start(XPassthrough_stream *InstancePtr) {
    u32 Data;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XPassthrough_stream_ReadReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_AP_CTRL) & 0x80;
    XPassthrough_stream_WriteReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_AP_CTRL, Data | 0x01);
}

u32 XPassthrough_stream_IsDone(XPassthrough_stream *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XPassthrough_stream_ReadReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_AP_CTRL);
    return (Data >> 1) & 0x1;
}

u32 XPassthrough_stream_IsIdle(XPassthrough_stream *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XPassthrough_stream_ReadReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_AP_CTRL);
    return (Data >> 2) & 0x1;
}

u32 XPassthrough_stream_IsReady(XPassthrough_stream *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XPassthrough_stream_ReadReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_AP_CTRL);
    // check ap_start to see if the pcore is ready for next input
    return !(Data & 0x1);
}

void XPassthrough_stream_EnableAutoRestart(XPassthrough_stream *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XPassthrough_stream_WriteReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_AP_CTRL, 0x80);
}

void XPassthrough_stream_DisableAutoRestart(XPassthrough_stream *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XPassthrough_stream_WriteReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_AP_CTRL, 0);
}

void XPassthrough_stream_Set_n_samples(XPassthrough_stream *InstancePtr, u32 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XPassthrough_stream_WriteReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_N_SAMPLES_DATA, Data);
}

u32 XPassthrough_stream_Get_n_samples(XPassthrough_stream *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XPassthrough_stream_ReadReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_N_SAMPLES_DATA);
    return Data;
}

void XPassthrough_stream_InterruptGlobalEnable(XPassthrough_stream *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XPassthrough_stream_WriteReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_GIE, 1);
}

void XPassthrough_stream_InterruptGlobalDisable(XPassthrough_stream *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XPassthrough_stream_WriteReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_GIE, 0);
}

void XPassthrough_stream_InterruptEnable(XPassthrough_stream *InstancePtr, u32 Mask) {
    u32 Register;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Register =  XPassthrough_stream_ReadReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_IER);
    XPassthrough_stream_WriteReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_IER, Register | Mask);
}

void XPassthrough_stream_InterruptDisable(XPassthrough_stream *InstancePtr, u32 Mask) {
    u32 Register;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Register =  XPassthrough_stream_ReadReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_IER);
    XPassthrough_stream_WriteReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_IER, Register & (~Mask));
}

void XPassthrough_stream_InterruptClear(XPassthrough_stream *InstancePtr, u32 Mask) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XPassthrough_stream_WriteReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_ISR, Mask);
}

u32 XPassthrough_stream_InterruptGetEnabled(XPassthrough_stream *InstancePtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    return XPassthrough_stream_ReadReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_IER);
}

u32 XPassthrough_stream_InterruptGetStatus(XPassthrough_stream *InstancePtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    return XPassthrough_stream_ReadReg(InstancePtr->Ctrl_BaseAddress, XPASSTHROUGH_STREAM_CTRL_ADDR_ISR);
}

