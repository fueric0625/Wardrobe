# u2netp.onnx

Lightweight U²-Net (U2NETP) converted by [rembg](https://github.com/danielgatis/rembg).

- Source: https://github.com/danielgatis/rembg/releases/download/v0.0.0/u2netp.onnx
- MD5: `8e83ca70e441ab06c318d82300c84806`
- Original U²-Net: Apache-2.0 (https://github.com/xuebinqin/U-2-Net)

# MobileSAM (encoder + decoder)

Split ONNX for click refine: image encoder once per photo, prompt decoder on each click.

- Encoder: `mobile_sam_encoder.onnx` from [Acly/MobileSAM](https://huggingface.co/Acly/MobileSAM/blob/main/mobile_sam_image_encoder.onnx) (`mobile_sam_image_encoder.onnx`)
- Decoder: `mobile_sam_decoder.onnx` from [Acly/MobileSAM](https://huggingface.co/Acly/MobileSAM/blob/main/sam_mask_decoder_single.onnx) (`sam_mask_decoder_single.onnx`)
- Original MobileSAM: Apache-2.0 (https://github.com/ChaoningZhang/MobileSAM)
