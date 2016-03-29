IDL=idl

.PHONY: doc

doc:
	$(IDL) -e kcor_make_docs
