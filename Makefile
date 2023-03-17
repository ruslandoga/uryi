all: priv/td_nif.so

priv/td_nif.so: c_src/td_nif.c
	gcc c_src/td_nif.c -o priv/td_nif.so -ltdjson -undefined dynamic_lookup -dynamiclib -I"$(ERTS_INCLUDE_DIR)"

clean:
	rm -f $(NIF_NAME).so

.PHONY: all clean
