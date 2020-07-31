# Targets that do not create files
.PHONY: all clean test


# Rule to the entire pipeline
all:

# Rule to remove all generated output; see some examples below
clean:
	rm -f data/raw/*.csv
	rm -f data/processed/*.pickle
	rm -f data/processed/*.xlsx
	rm -f reports/figures/*.png
	rm -f models/*.model

# Add additional rules below (e.g. rule for downloading raw data)

# Rule for testing
test: all
	pytest src
