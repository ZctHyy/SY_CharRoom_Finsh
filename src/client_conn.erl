%%----------------------------------------------------
%% @doc 链接维持进程
%% 
%% @author Jangee@qq.com
%% @end
%%----------------------------------------------------
-module(client_conn).
-behaviour(gen_server).
-export([
        start/1
        ,send/3
    ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("common.hrl").
-include("client.hrl").

start(Sock) ->
    gen_server:start_link(?MODULE, [Sock], []).

init([Sock]) ->
    Client = #client{socket = Sock},
    %%检查用户是否已链接，已连接更换connid，断开原有Connid
    ets:insert(client, client),
    {ok, Client}.

handle_call(_Request, _From, Client) ->
    {noreply, Client}.

handle_cast(_Msg, Client) ->
    {noreply, Client}.


handle_info({tcp,_,Msg},Client) ->
    io:format("get msg : ~p ~n",[Msg]),
    {noreply, Client};

handle_info(_Info, Client) ->
    {noreply, Client}.

terminate(_Reason, _Client) ->
    ok.

code_change(_OldVsn, Client, _Extra) ->
    {ok, Client}.

send(Socket, 101, _Role) ->
    Msg = <<"ok">>,
    case gen_tcp:send(Socket, Msg) of
        ok -> 
            ok;
        {false, Reason} ->
            {false, Reason}
    end.
    
