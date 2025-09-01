# BraDiPho: Brain Dissection Photogrammetry

BraDiPho is an innovative framework for exploring human brain anatomy by integrating ex-vivo microdissection and in-vivo tractography data. It leverages photogrammetry to provide detailed 3D models of brain dissections, enabling interactive and educational insights into white matter structures.

## Data source and documentation

BraDiPho provides tools, models, and tutorials for integration and exploration of brain anatomy data. Learn more on the official website:

- [BraDiPho Website](https://bradipho.eu/)
- [BraDiPho OHBM Talk 2023](https://www.youtube.com/watch?v=CAg3BkaPPwY)
- [BraDiPhoPy Repository](https://github.com/minilabus/bradiphopy)
- [Registration Files on Zenodo](https://zenodo.org/records/11192915)

## Running BraDiPho with Docker or Singularity

The most efficient way to use this pipeline is through Docker or Singularity, ensuring all dependencies are managed and isolated.

### Building the Docker or Singularity image

To build the required container, use the following commands:

#### **Docker:**
```bash
docker build . -t "bradipho" --rm --no-cache
```

#### **Singularity:**
```bash
singularity build bradipho.sif docker-daemon://bradipho:latest
```

### Example command to launch the pipeline

#### **Singularity Execution:**
```bash
singularity exec bradipho.sif bash /bdp_registration_utils/launch_registration.sh ${PATH_TO_INPUT_DATA}/ sub-01 ${PATH_TO_OUTPUT_DATA}
# Unless from the internal team or reprocessing data, this is the only command you should use
```


- `sub-01` is an example subject identifier from BraDiPho; adjust as needed.
    (sub-01, sub-02, sub-04, sub-10, sub-16, sub-17, sub-18, sub-19)
- Replace `${PATH_TO_INPUT_DATA}` with the path to your input data directory.
    Your folder can contains Nifti (.nii, .nii.gz), tractography (.trk, .tck), and surfaces (.vtk, .ply)
    ```
    input/
    ├── atlas.nii.gz (labels, uint16)
    ├── laf_m.tck
    ├── lh.ply
    ├── lpt_m.tck
    ├── raf_m.trk
    ├── rh.ply
    ├── rpt_m.trk
    ├── t1_mask.nii.gz (mask, uint8)
    ├── t1.nii.gz (image, float32)
    └── wm.nii (mask, uint8)
    ```
- You should have at least one 'image' that can be used for registration (T1w, FA, etc.) and this image should be skull-stripped.