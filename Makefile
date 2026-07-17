.PHONY: check server-test firmware cad bom repo-check

PYTHON ?= python3
PIO ?= pio

server-test:
	$(PYTHON) -m unittest discover -s server/tests -v
	$(PYTHON) -m compileall -q server tools

firmware:
	$(PIO) run --project-dir firmware

cad:
	$(MAKE) -C hardware/cad check-release

bom:
	$(PYTHON) tools/check_bom.py

repo-check:
	$(PYTHON) tools/check_repo.py

check: server-test bom repo-check firmware cad
