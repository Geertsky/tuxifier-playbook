#!/usr/bin/env bash
filename="$1"

conda_env=$(conda info|awk -F: '{ if ($1~ /.*active environment.*/) print $NF}'|xargs)
if [ "$conda_env" != "ggdefault" ]; then conda activate ggdefault; deactivate_conda_env=1; fi

output=${filename::-3}.pdf
pandoc -F mermaid-filter --pdf-engine tectonic $filename -o $output

if [ -n "$deactivate_conda_env" ]; then conda deactivate; fi
