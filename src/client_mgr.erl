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
    ?P("开始启动.client_mgr.erl.~n"),
    %%named_table,代表可以直接用表名进行操作
    %%而最后一个参数则是用#client.id作为键然后去获取整个{keypos，#client.id}的值。  
    ets:new(croom, [set, named_table, public , {keypos,#croom.name}]),
    %%这也是聊天室的配置表，主要是房间的配置。	    
    ets:new(client, [set, named_table, public, {keypos, #client.id}]),
    %%这是整个聊天室的客户记录表。
    {ok, Listen} = gen_tcp:listen(?port, [binary,{active,  true}, {reuseaddr, true}]),
    %%监听8100端口，创建主动套接字，且多个实例可用一个端口。
    State = #state{socket = Listen, acceptors = empty_listeners(5, Listen)},
    %%挂起连接，等待客户端链接进来获取其套接字进行通信.
    ?P("启动完成.client_mgr.erl~n"),
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
