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

# RapidOCR PP-OCRv4 (hangtag)

Detection + recognition ONNX plus PaddleOCR character dict. Loaded through the existing ONNX Runtime FFI (no cloud, no Python, no Flutter OCR plugin).

- Detector: `ppocr_v4_det.onnx` from [SWHL/RapidOCR](https://huggingface.co/SWHL/RapidOCR)
- Recognizer: `ppocr_v4_rec.onnx` from [SWHL/RapidOCR](https://huggingface.co/SWHL/RapidOCR)
- Keys: `ppocr_keys_v1.txt` (PaddleOCR PP-OCR dict; CTC blank is index 0, space is the extra last class, giving 6625 classes)
- PaddleOCR: Apache-2.0 (https://github.com/PaddlePaddle/PaddleOCR)
