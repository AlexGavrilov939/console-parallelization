# See https://tech.davis-hansson.com/p/make/
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules


.DEFAULT_GOAL := all


# Global variables
OS := $(shell uname)
PHPNOGC=php -d zend.enable_gc=0
CCYELLOW=\033[0;33m
CCEND=\033[0m

# PHP specific variables
SRC_TESTS_FILES=$(shell find src/ tests/ -type f)
COVERAGE_DIR = dist/coverage
COVERAGE_XML = $(COVERAGE_DIR)/xml
COVERAGE_JUNIT = $(COVERAGE_DIR)/phpunit.junit.xml
COVERAGE_HTML = $(COVERAGE_DIR)/html
TARGET_MSI = 100

PHP_CS_FIXER_BIN = vendor-bin/php-cs-fixer/vendor/friendsofphp/php-cs-fixer/php-cs-fixer
PHP_CS_FIXER = $(PHPNOGC) $(PHP_CS_FIXER_BIN)

PHPSTAN_BIN = vendor/phpstan/phpstan/phpstan
PHPSTAN = $(PHPSTAN_BIN)

PHPUNIT_BIN = vendor/bin/phpunit
PHPUNIT = $(PHPUNIT_BIN)
PHPUNIT_COVERAGE_INFECTION = XDEBUG_MODE=coverage $(PHPUNIT) --exclude-group autoreview --coverage-xml=$(COVERAGE_XML) --log-junit=$(COVERAGE_JUNIT)
PHPUNIT_COVERAGE_HTML = XDEBUG_MODE=coverage $(PHPUNIT) --coverage-html=$(COVERAGE_HTML)

INFECTION_BIN = vendor/bin/infection
INFECTION = $(INFECTION_BIN) --skip-initial-tests --coverage=$(COVERAGE_DIR) --only-covered --show-mutations --min-msi=$(TARGET_MSI) --min-covered-msi=$(TARGET_MSI) --ansi --threads=max
INFECTION_WITH_INITIAL_TESTS = $(INFECTION_BIN) --only-covered --show-mutations --min-msi=$(TARGET_MSI) --min-covered-msi=$(TARGET_MSI) --ansi --threads=max


#
# Commands
#---------------------------------------------------------------------------

.PHONY: all
all: cs validate-package phpstan infection

.PHONY: help
help:
	@echo "\033[33mUsage:\033[0m\n  make TARGET\n\n\033[32m#\n# Commands\n#---------------------------------------------------------------------------\033[0m\n"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//' | awk 'BEGIN {FS = ":"}; {printf "\033[33m%s:\033[0m%s\n", $$1, $$2}'

.PHONY: cs
cs: 	 	  ## Fixes CS
cs: php_cs_fixer gitignore_sort composer_normalize

.PHONY: php_cs_fixer
php_cs_fixer: 	  ## Runs PHP-CS-Fixer
php_cs_fixer: $(PHP_CS_FIXER_BIN)
	$(PHP_CS_FIXER) fix

.PHONY: gitignore_sort
gitignore_sort:	  ## Sorts the .gitignore entries
gitignore_sort:
	LC_ALL=C sort -u .gitignore -o .gitignore

.PHONY: composer_normalize
composer_normalize:  ## Normalizes the composer.json
composer_normalize:	vendor
	composer normalize

.PHONY: test
test: 	 	  ## Runs all the tests
test: validate-package phpstan phpunit

.PHONY: phpstan
phpstan: 	  ## Runs PHPStan
phpstan: phpstan_src phpstan_tests

.PHONY: phpstan_src
phpstan_src: $(PHPSTAN_BIN) vendor
	$(PHPSTAN) analyze --configuration phpstan-src.neon.dist

.PHONY: phpstan_tests
phpstan_tests: $(PHPSTAN_BIN) vendor
	$(PHPSTAN) analyze --configuration phpstan-tests.neon.dist

.PHONY: phpunit
phpunit:	  ## Runs PHPUnit
phpunit: $(PHPUNIT_BIN)
	$(PHPUNIT)

.PHONY: phpunit_coverage_infection
phpunit_coverage_infection: ## Runs PHPUnit with code coverage for Infection
phpunit_coverage_infection: $(PHPUNIT_BIN) vendor
	$(PHPUNIT_COVERAGE_INFECTION)

.PHONY: phpunit_coverage_html
phpunit_coverage_html:	    ## Runs PHPUnit with code coverage with HTML report
phpunit_coverage_html: $(PHPUNIT_BIN) vendor
	$(PHPUNIT_COVERAGE_HTML)
	@echo "You can check the report by opening the file \"$(COVERAGE_HTML)/index.html\"."

.PHONY: infection
infection:	  ## Runs Infection
infection: $(INFECTION_BIN) vendor
	$(INFECTION_WITH_INITIAL_TESTS)

.PHONY: _infection
_infection: $(INFECTION_BIN) $(COVERAGE_XML) $(COVERAGE_JUNIT) vendor
	$(INFECTION)

.PHONY: validate-package
validate-package: ## Validates the Composer package
validate-package: vendor
	composer validate --strict

.PHONY: clear
clear: 	  	  ## Clears various artifacts
clear: clear_cache clear_coverage

.PHONY: clear_cache
clear_cache: 	  ## Clears the integration test app cache
clear_cache:
	rm -rf tests/Integration/**/cache || true

.PHONY: clear_coverage
clear_coverage:	  ## Clears the coverage reports
clear_coverage:
	rm -rf $(COVERAGE_DIR) || true


#
# Rules from files
#---------------------------------------------------------------------------

composer.lock: composer.json
	composer install
	touch -c $@

vendor: composer.lock
	composer install
	touch -c $@

$(PHP_CS_FIXER_BIN): vendor
	composer bin php-cs-fixer install
	touch -c $@

$(PHPSTAN_BIN): vendor
	touch -c $@

$(PHPUNIT_BIN): vendor
	touch -c $@

$(COVERAGE_XML): $(PHPUNIT_BIN) $(SRC_TESTS_FILES) phpunit.xml.dist
	$(MAKE) phpunit_coverage_infection
	touch -c $@
	touch -c $(COVERAGE_JUNIT)

$(COVERAGE_JUNIT): $(PHPUNIT_BIN) $(SRC_TESTS_FILES) phpunit.xml.dist
	$(MAKE) phpunit_coverage_infection
	touch -c $@
	touch -c $(COVERAGE_XML)

$(INFECTION_BIN): vendor
	touch -c $@
