%%----------------------------------------------------
%% @doc 链接管理进程
%% 
%% @author Jangee@qq.com
%% @end
%%----------------------------------------------------
-module(client_mgr).
-behaviour(gen_server).
-export([
        start_link/0
    ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("common.hrl").
-include("client.hrl").

-define(port,8100).

-record(state, {
        socket :: reference()
        ,acceptors = []
    }).

%%----------------------------------------------------
%% OTP APIS
%%----------------------------------------------------

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    ?P("开始启动..~n"),
    ets:new(client, [set, named_table, public, {keypos, #client.id}]),
    {ok, Listen} = gen_tcp:listen(?port, [list,{active,  true}, {reuseaddr, true}]),
    State = #state{socket = Listen, acceptors = empty_listeners(5, Listen)},
    ?P("启动完成~n"),
    {ok, State}.

handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%----------------------------------------------------
%% 内部函数
%%----------------------------------------------------
empty_listeners(N, LSock) ->
    [start_socket(LSock) || _ <- lists:seq(1,N)].

start_socket(LSock) ->
    supervisor:start_child(client_sup, [LSock]).
