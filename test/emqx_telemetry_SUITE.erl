%%--------------------------------------------------------------------
%% Copyright (c) 2020 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqx_telemetry_SUITE).

-compile(export_all).
-compile(nowarn_export_all).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

-import(proplists, [get_value/2]).

all() -> emqx_ct:all(?MODULE).

init_per_testcase(_, Config) ->
    emqx_ct_helpers:boot_modules(all),
    emqx_ct_helpers:start_apps([emqx_telemetry]),
    Config.

end_per_testcase(_, _Config) ->
    emqx_ct_helpers:stop_apps([emqx_telemetry]).

t_uuid(_) ->
    UUID = emqx_telemetry:generate_uuid(),
    Parts = binary:split(UUID, <<"-">>, [global, trim]),
    ?assertEqual(5, length(Parts)),
    {ok, UUID2} = emqx_telemetry:get_uuid(),
    emqx_telemetry:stop(),
    emqx_telemetry:start_link([{enabled, true},
                               {url, "https://telemetry.emqx.io/api/telemetry"},
                               {report_interval, 7 * 24 * 60 * 60}]),
    {ok, UUID3} = emqx_telemetry:get_uuid(),
    ?assertEqual(UUID2, UUID3).

t_get_telemetry(_) ->
    {ok, TelemetryData} = emqx_telemetry:get_telemetry(),
    OTPVersion = bin(erlang:system_info(otp_release)),
    ?assertEqual(OTPVersion, get_value(otp_version, TelemetryData)),
    {ok, UUID} = emqx_telemetry:get_uuid(),
    ?assertEqual(UUID, get_value(uuid, TelemetryData)),
    ?assertEqual(0, get_value(num_clients, TelemetryData)).

t_enable(_) ->
    ok = emqx_telemetry:enable(),
    ?assertEqual(true, emqx_telemetry:is_enabled()),
    ok = emqx_telemetry:disable(),
    ?assertEqual(false, emqx_telemetry:is_enabled()).

bin(L) when is_list(L) ->
    list_to_binary(L);
bin(B) when is_binary(B) ->
    B.