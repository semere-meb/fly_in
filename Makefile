SRC :=  drone_sprite.py \
	engine.py \
	errors.py \
	graph.py \
	main.py \
	models.py \
	parser.py \
	pathfinder.py \
	scheduler.py \
	visualizer.py \
	stubs/webcolors.pyi \

VENV := .venv
MYPY_OPTIONS := --warn-return-any \
	--warn-unused-ignores \
	--ignore-missing-imports \
	--disallow-untyped-defs \
	--check-untyped-defs

run: install
	uv run python -m main -m maps/challenger/01_the_impossible_dream.txt

install: $(VENV)

$(VENV): pyproject.toml uv.lock
	uv sync || pip install uv && uv sync
	ruff --version || pip install ruff

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	rm -rf .mypy_cache
	rm -rf .ruff_cache
	rm -rf .pytest_cache

lint: $(VENV)
	uvx ruff check $(SRC)
	uv run mypy $(SRC) $(MYPY_OPTIONS) --strict

test: $(VENV)
	uv run pytest

format:
	uvx ruff format $(SRC)

debug: $(VENV)
	uv run python -m pdb main.py -m maps/easy/03_basic_capacity.txt

re: clean install

.PHONY: install run clean lint debug re test
