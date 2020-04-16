%%----------------------------------------------------
%% @doc
%% 服务器链接处理
%% @author Raydraw@163.com
%% @end
%%----------------------------------------------------
-module(client).
-behaviour(gen_server).
-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {listen,socket,rid}).

-include("common.hrl").

start_link(ListenSocket) ->%%从sup那里拿到的LSOCK。
    gen_server:start_link(?MODULE, [ListenSocket], []).

init([ListenSocket]) ->
    ?P("start Connect ~n"),%%common.hrl中的宏定义，P(F).
	gen_server:cast(self(), accept),%%播发。此处发给自己一个accept原子消息，然后下面的handle_cast收到消息并开始处理.
    io:format("client:ListenSocket ~p ~n",[ListenSocket]),
    State = #state{listen = ListenSocket},%%定义记录，记录名字为state，里面包含了映射。
    {ok, State}.

handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(accept ,State) ->
    
    io:format("State: ~n~p",[State]),
    {ok, Connect} = gen_tcp:accept(State#state.listen),%%程序挂起并等待一个连接，当获取到连接的时候返回Connect绑定了可以和客户端连接的套接字。
    %%监听mgr哪里来的State端口.
    %%复制一份链接接口
    {ok, Pid} = client_conn:start(Connect),%%已经开始跑动起来（相当于后台）,就是真的跑起来一个功能的后台模块.
    io:format("client_conn:startPID ~p ~n",[Pid]),
    gen_tcp:controlling_process(Connect, Pid),%%所有创建了套接字的进程叫做控制进程，我们这里的控制进程是mgr那里跑起来的，然后我们这里用client_conn哪里处理问题，所以就要绑定另外一个PID。因此之后我们所处理的东西都会转过去。
    gen_server:cast(self(), accept),
    NewState = State#state{socket = Connect},
    io:format("NewState: ~n ~p",[NewState]),
    {noreply,NewState};%%产生新的状态。
handle_cast(_Msg, State) ->
    {noreply, State}.
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
