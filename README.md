# BraDiPho: Brain Dissection Photogrammetry

BraDiPho is an innovative framework for exploring human brain anatomy by integrating ex-vivo microdissection and in-vivo tractography data. It leverages photogrammetry to provide detailed 3D models of brain dissections, enabling interactive and educational insights into white matter structures.

## Data Source and Documentation

BraDiPho provides tools, models, and tutorials for integration and exploration of brain anatomy data. Learn more on the official website:

- [BraDiPho Website](https://bradipho.eu/)
- [BraDiPho OHBM Talk 2023](https://www.youtube.com/watch?v=CAg3BkaPPwY)
- [BraDiPhoPy Repository](https://github.com/minilabus/bradiphopy)
- [Registration Files on Zenodo](https://zenodo.org/records/11192915)

## Features

- **Integration of Ex-Vivo and In-Vivo Data**: Combines microdissection and tractography in a common neuroradiological space.
- **High-Resolution 3D Models**: Includes photogrammetric reconstructions for detailed exploration.

## Running BraDiPho with Docker or Singularity

The most efficient way to use this pipeline is through Docker or Singularity, ensuring all dependencies are managed and isolated.

### Building the Docker or Singularity Image

To build the required container, use the following commands:

#### **Docker:**
```bash
docker build . -t "bradipho" --rm --no-cache
```

#### **Singularity:**
```bash
singularity build bradipho.sif docker-daemon://bradipho:latest
```

### Example Command to Launch the Pipeline

#### **Singularity Execution:**
```bash
singularity exec bradipho.sif bash /bdp_registration_utils/launch_registration.sh ${PATH_TO_INPUT_DATA}/ sub-01 ${PATH_TO_OUTPUT_DATA}
```

- Replace `${PATH_TO_INPUT_DATA}` with the path to your input data directory.
- `sub-01` is an example subject identifier; adjust as needed.
    (sub-01, sub-02, sub-04, sub-10, sub-16, sub-17, sub-18, sub-19)

This setup allows you to easily process your data and integrate it into the BraDiPho framework.