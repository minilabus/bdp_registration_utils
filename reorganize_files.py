#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Internal use only


"""
Scripts to reorganize a folder full of various file format into 4 folders:
  - images/
  - labels_masks/
  - meshes_point_clouds/
  - streamlines/
"""

import argparse
import os
import shutil

import nibabel as nib
import numpy as np

from scilpy.io.utils import assert_headers_compatible
from scilpy.utils.filenames import split_name_with_nii


def _build_arg_parser():
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    p.add_argument('in_folder',
                   help='Input folder.')
    p.add_argument('out_folder',
                   help='Output folder.')
    p.add_argument('--overwrite', '-f', action='store_true',
                   help='Overwrite existing files.')
    return p


def main():
    parser = _build_arg_parser()
    args = parser.parse_args()

    # This is fixed number, above Glasser and Schaefer800, will often confuse density map from small bundles
    MAX_NUM_LABELS = 1000

    if os.path.exists(args.out_folder) and args.overwrite:
        shutil.rmtree(args.out_folder)
    if not os.path.exists(args.out_folder):
        os.mkdir(args.out_folder)

    os.mkdir(os.path.join(args.out_folder, "images"))
    os.mkdir(os.path.join(args.out_folder, "labels_masks"))
    os.mkdir(os.path.join(args.out_folder, "streamlines"))
    os.mkdir(os.path.join(args.out_folder, "meshes_point_clouds"))

    ref = None
    for root, dirs, files in os.walk(args.in_folder):
        for file in files:
            _, ext = split_name_with_nii(file)
            if ext in ['.vtk', '.vtp', '.fib', '.ply', '.stl', '.xml', '.obj']:
                shutil.copy(os.path.join(root, file),
                            os.path.join(args.out_folder, "meshes_point_clouds",
                                         file))
            elif ext in ['.nii', '.nii.gz']:
                path = os.path.join(root, file)
                if ref is None:
                    ref = path
                    shutil.copy(os.path.join(root, file),
                                os.path.join(args.out_folder, 'reference'+ext))
                assert_headers_compatible(ref, path)
                img = nib.load(os.path.join(root, file))
                data = img.get_fdata()
                values = np.unique(data)

                if np.allclose(np.mod(values, 1), 0, atol=1e-6):
                    if len(values) < MAX_NUM_LABELS:
                        shutil.copy(os.path.join(root, file),
                                    os.path.join(args.out_folder, "labels_masks",
                                                 file))
                    else:
                        print(f"Skipping {file} because it has more than "
                              f"{MAX_NUM_LABELS} labels. Uncertain "
                              "classification.")
                else:
                    ref = path
                    os.remove(os.path.join(args.out_folder, 'reference'+ext))
                    shutil.copy(os.path.join(root, file),
                                os.path.join(args.out_folder, 'reference'+ext))
                    shutil.copy(os.path.join(root, file),
                                os.path.join(args.out_folder, "images", file))

            elif ext in ['.trk', '.tck']:
                shutil.copy(os.path.join(root, file),
                            os.path.join(args.out_folder, "streamlines", file))
            else:
                print(f"Skipping {file} because it is not a supported file "
                      "format.")


if __name__ == "__main__":
    main()
