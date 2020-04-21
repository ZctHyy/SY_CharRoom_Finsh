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
-include("croom.hrl").

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
    %%启动监听

    ets:new(client, [set, named_table, public, {keypos, #client.id}]),
    {ok, Listen} = gen_tcp:listen(?port, [binary,{active,  true}, {reuseaddr, true}]),  %%发送类型自动转成binary
    %%创建5个连接
    State = #state{socket = Listen, acceptors = empty_listeners(5, Listen)},
    user_manager:start_link(),
    room_manager:start_link(),
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
empty_listeners(N, LSock) ->%%该程序是列表1到5跑了5次，所以产生了5个client_sup的进程。
    [start_socket(LSock) || _ <- lists:seq(1,N)].

start_socket(LSock) ->
    supervisor:start_child(client_sup, [LSock]).
