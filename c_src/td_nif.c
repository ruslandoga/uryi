#include <erl_nif.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <td/telegram/td_json_client.h>

ErlNifResourceType* __TDLIB_RESOURCE__;

typedef struct {
  void* client;
} TDLib;

static ERL_NIF_TERM make_binary(ErlNifEnv* env, const void* bytes,
                                unsigned int size) {
  ErlNifBinary blob;
  ERL_NIF_TERM term;

  if (!enif_alloc_binary(size, &blob)) {
    return enif_make_atom(env, "out_of_memory");
  }

  memcpy(blob.data, bytes, size);
  term = enif_make_binary(env, &blob);
  enif_release_binary(&blob);

  return term;
}

ERL_NIF_TERM create(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  void* client = td_json_client_create();
  if (!client) return enif_make_atom(env, "error");

  TDLib* tdlib = enif_alloc_resource(__TDLIB_RESOURCE__, sizeof(TDLib));
  tdlib->client = client;

  ERL_NIF_TERM result = enif_make_resource(env, tdlib);
  enif_release_resource(tdlib);

  return enif_make_tuple2(env, enif_make_atom(env, "ok"), result);
}

ERL_NIF_TERM send(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  TDLib* tdlib;
  ErlNifBinary json;
  ERL_NIF_TERM eos = enif_make_int(env, 0);

  if (!enif_get_resource(env, argv[0], __TDLIB_RESOURCE__, (void**)&tdlib)) {
    return enif_make_badarg(env);
  }

  if (!enif_inspect_iolist_as_binary(env, enif_make_list2(env, argv[1], eos),
                                     &json)) {
    return enif_make_badarg(env);
  }

  td_json_client_send(tdlib->client, (char*)json.data);
  return enif_make_atom(env, "ok");
}

// ERL_NIF_TERM execute(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
//   TDLib* tdlib;
//   ErlNifBinary json;
//   ERL_NIF_TERM eos = enif_make_int(env, 0);

//   if (!enif_get_resource(env, argv[0], __TDLIB_RESOURCE__, (void**)&tdlib)) {
//     return enif_make_badarg(env);
//   }

//   if (!enif_inspect_iolist_as_binary(env, enif_make_list2(env, argv[1], eos),
//                                      &json)) {
//     return enif_make_badarg(env);
//   }

//   (char*)r = td_json_client_execute(tdlib->client, (char*)json.data);
//   return enif_make_tuple2(env, enif_make_atom(env, "ok"), make_binary(env,
//   ));
// }

ERL_NIF_TERM recv(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  TDLib* tdlib;
  double timeout;

  if (!enif_get_resource(env, argv[0], __TDLIB_RESOURCE__, (void**)&tdlib)) {
    return enif_make_badarg(env);
  }

  if (!enif_get_double(env, argv[1], &timeout)) {
    return enif_make_badarg(env);
  }

  const char* response = td_json_client_receive(tdlib->client, timeout);

  if (!response) {
    return enif_make_tuple2(env, enif_make_atom(env, "ok"),
                            enif_make_atom(env, "nil"));
  }

  ERL_NIF_TERM json = make_binary(env, response, strlen(response));
  return enif_make_tuple2(env, enif_make_atom(env, "ok"), json);
}

// void destroy() { td_json_client_destroy(self.instance) }

static ErlNifFunc nif_funcs[] = {
    {"create", 0, create},
    {"send", 2, send},  //{"execute", 2, execute},
    {"recv", 2, recv, ERL_NIF_DIRTY_JOB_IO_BOUND},
};

static int load(ErlNifEnv* env, void** priv, ERL_NIF_TERM load_info) {
  int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
  __TDLIB_RESOURCE__ =
      enif_open_resource_type(env, "nif", "TDLib", NULL, flags, NULL);
  return 0;
}

ERL_NIF_INIT(Elixir.Uryi.TDNif, nif_funcs, &load, NULL, NULL, NULL);
