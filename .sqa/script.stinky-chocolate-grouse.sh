(
cd github.com/I2PC/scipion-docker &&
    bandit -f json --quiet  --confidence-level high --severity-level high --recursive .
)