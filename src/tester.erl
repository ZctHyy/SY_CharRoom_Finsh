%%----------------------------------------------------
%% @doc
%% 客户端模拟器
%% @author Raydraw@163.com
%% @end
%%----------------------------------------------------
-module(tester).
-behaviour(gen_server).
-export([start_link/0,start/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {socket}).

-define(Port,8749).

start_link() ->
gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

start() ->
gen_server:start({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    State = #state{},
    gen_server:cast(self(),connect),
    {ok, State}.

handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(connect , State) ->
    {ok,Socket } = gen_tcp:connect("127.0.0.1",?Port , []),
    {noreply, State#state{socket = Socket}};
handle_cast({send,Msg},State) -> 
    gen_tcp:send(State#state.socket, Msg),
    {noreply,State};
handle_cast({json,Msg}, State) ->
    NMsg = mochijson:encode({struct,Msg}),
    gen_tcp:send(State#state.socket,NMsg),
    {noreply,State};
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({tcp,Msg}, State) ->
    io:format("server send msg : ~p ~n ",[Msg]),
    {noreply,State};
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
