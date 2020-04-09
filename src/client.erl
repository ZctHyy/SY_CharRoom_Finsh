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

start_link(ListenSocket) ->
    gen_server:start_link(?MODULE, [ListenSocket], []).

init([ListenSocket]) ->
    ?P("start Connect ~n"),
	gen_server:cast(self(), accept),
    State = #state{listen = ListenSocket},
    {ok, State}.

handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(accept ,State) ->
    {ok, Connect} = gen_tcp:accept(State#state.listen),
    io:format("accept ~p ~n",[Connect]),
    %%复制一份链接接口
    {ok, Pid} = client_conn:start(Connect),
    gen_tcp:controlling_process(Connect, Pid),
    gen_server:cast(self(), accept),
    NewState = State#state{socket = Connect},
    {noreply,NewState};
handle_cast(_Msg, State) ->
    {noreply, State}.
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
