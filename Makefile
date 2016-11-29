.PHONY: doc sswdeps help

FLAGS=
VERBOSE=0

GIT=/usr/bin/git

REVISION:=$(shell $(GIT) rev-parse --short HEAD)
PHONE=$(shell cat $(HOME)/.phonenumber 2> /dev/null)
EMAIL=$(USER)@ucar.edu

IDL=idl
SSWDEPS_IDL=idl85

ifeq ($(VERBOSE), 1)
  ECHO_PREFIX=
else
  ECHO_PREFIX=@
endif

SSW_DIR=$(PWD)/ssw
GEN_DIR=$(PWD)/gen
LIB_DIR=$(PWD)/lib
KCOR_SRC_DIR=$(PWD)/src

FULL_SSW_DIR=/hao/contrib/ssw

KCOR_PATH=+$(KCOR_SRC_DIR):$(SSW_DIR):$(GEN_DIR):+$(LIB_DIR):"<IDL_DEFAULT>"
DOC_PATH=$(MGLIB_DIR):$(IDLDOC_DIR):$(COMP_PATH)
UNIT_PATH=$(PWD)/unit:$(MGUNIT_DIR):$(COMP_PATH)

SSW_DEP_PATH="<IDL_DEFAULT>":$(KCOR_PATH):+$(FULL_SSW_DIR)

doc:
	$(IDL) -e kcor_make_docs

sswdeps:
	@echo "Find ROUTINES..."
	$(ECHO_PREFIX)find src -name '*.pro' -exec basename {} .pro \; > ROUTINES
	$(ECHO_PREFIX)find gen -name '*.pro' -exec basename {} .pro \; >> ROUTINES
	@echo "Starting IDL..."
	$(ECHO_PREFIX)$(SSWDEPS_IDL) -IDL_STARTUP "" -IDL_PATH $(SSW_DEP_PATH) -e "kcor_find_ssw_dependencies, '$(FULL_SSW_DIR)'" 2> /dev/null


help:
	@echo "Makefile targets:"
	@echo "  doc         generate KCor pipeline IDL API documentation"
	@echo "  sswdeps     find SSW IDL not in ssw/ directory"
