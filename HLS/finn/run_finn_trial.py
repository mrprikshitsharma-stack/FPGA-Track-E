from finn.builder.build_dataflow import build_dataflow_cfg
from finn.builder.build_dataflow_config import (
    DataflowBuildConfig,
    ShellFlowType,
    DataflowOutputType,
)

cfg = DataflowBuildConfig(
    output_dir="finn_output",

    synth_clk_period_ns=10.0,

    generate_outputs=[
        DataflowOutputType.STITCHED_IP
    ],

    mvau_wwidth_max=36,
    target_fps=1000,

    board="Pynq-Z1",
    shell_flow_type=ShellFlowType.VIVADO_ZYNQ,

    steps=[
        "step_qonnx_to_finn",
        "step_tidy_up",
        "step_streamline",
        "step_convert_to_hw",
        "step_create_stitched_ip",
    ]
)

build_dataflow_cfg("toy_model.onnx", cfg)

print("FINN flow completed.")
