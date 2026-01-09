.PHONY: all fixtures clean benchmark

FIXTURES_DIR := Fixtures

all: fixtures

# Download JSON test fixtures from nativejson-benchmark
# These are popular fixtures used in JSON parser benchmarks
fixtures: $(FIXTURES_DIR)/twitter.json $(FIXTURES_DIR)/citm_catalog.json $(FIXTURES_DIR)/canada.json

$(FIXTURES_DIR)/twitter.json:
	@mkdir -p $(FIXTURES_DIR)
	curl -sL "https://raw.githubusercontent.com/miloyip/nativejson-benchmark/master/data/twitter.json" -o "$@"

$(FIXTURES_DIR)/citm_catalog.json:
	@mkdir -p $(FIXTURES_DIR)
	curl -sL "https://raw.githubusercontent.com/miloyip/nativejson-benchmark/master/data/citm_catalog.json" -o "$@"

$(FIXTURES_DIR)/canada.json:
	@mkdir -p $(FIXTURES_DIR)
	curl -sL "https://raw.githubusercontent.com/miloyip/nativejson-benchmark/master/data/canada.json" -o "$@"

clean:
	rm -rf $(FIXTURES_DIR)

benchmark: fixtures
	swift package benchmark

benchmark-baseline: fixtures
	swift package benchmark --baseline default

benchmark-compare: fixtures
	swift package benchmark --baseline default --check-absolute
