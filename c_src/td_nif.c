#include <erl_nif.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <td/telegram/td_json_client.h>

static ERL_NIF_TERM make_atom(ErlNifEnv* env, const char* atom_name) {
  ERL_NIF_TERM atom;

  if (enif_make_existing_atom(env, atom_name, &atom, ERL_NIF_LATIN1)) {
    return atom;
  }

  return enif_make_atom(env, atom_name);
}

static ERL_NIF_TERM make_binary(ErlNifEnv* env, const void* bytes,
                                unsigned int size) {
  ErlNifBinary blob;
  ERL_NIF_TERM term;

  if (!enif_alloc_binary(size, &blob)) {
    return make_atom(env, "out_of_memory");
  }

  memcpy(blob.data, bytes, size);
  term = enif_make_binary(env, &blob);
  enif_release_binary(&blob);

  return term;
}

static const char* get_iodata(ErlNifEnv* env, ERL_NIF_TERM term) {
  ErlNifBinary bin;
  ERL_NIF_TERM eos = enif_make_int(env, 0);
  ERL_NIF_TERM list = enif_make_list2(env, term, eos);

  if (!enif_inspect_iolist_as_binary(env, list, &bin)) {
    return enif_make_badarg(env);
  }

  return bin.data;
}

ERL_NIF_TERM create_client_id(ErlNifEnv* env, int argc,
                              const ERL_NIF_TERM argv[]) {
  int client_id = td_create_client_id();
  return enif_make_int(env, client_id);
}

ERL_NIF_TERM send(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  int client_id;
  if (!enif_get_int(env, argv[0], &client_id)) return enif_make_badarg(env);

  const char* request = get_iodata(env, argv[1]);
  td_send(client_id, request);

  return make_atom(env, "ok");
}

ERL_NIF_TERM execute(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  const char* request = get_iodata(env, argv[0]);
  const char* response = td_execute(request);
  return make_binary(env, response, strlen(response));
}

ERL_NIF_TERM receive(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  double timeout;
  if (!enif_get_double(env, argv[0], &timeout)) return enif_make_badarg(env);

  const char* response = td_receive(timeout);
  if (!response) return make_atom(env, "nil");

  return make_binary(env, response, strlen(response));
}

static ErlNifFunc nif_funcs[] = {
    {"create_client_id", 0, create_client_id},
    {"send", 2, send},
    {"execute", 1, execute},
    {"recv", 1, receive, ERL_NIF_DIRTY_JOB_IO_BOUND},
};

ERL_NIF_INIT(Elixir.TD.Nif, nif_funcs, NULL, NULL, NULL, NULL);
