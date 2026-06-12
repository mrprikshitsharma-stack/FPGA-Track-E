set SynModuleInfo {
  {SRCNAME passthrough_stream MODELNAME passthrough_stream RTLNAME passthrough_stream IS_TOP 1
    SUBMODULES {
      {MODELNAME passthrough_stream_ctrl_s_axi RTLNAME passthrough_stream_ctrl_s_axi BINDTYPE interface TYPE interface_s_axilite}
      {MODELNAME passthrough_stream_regslice_both RTLNAME passthrough_stream_regslice_both BINDTYPE interface TYPE interface_regslice INSTNAME passthrough_stream_regslice_both_U}
    }
  }
}
