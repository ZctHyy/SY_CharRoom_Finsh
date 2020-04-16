%%----------------------------------------------------
%% @doc
%% 客户端监控树
%% @author Raydraw@163.com
%% @end
%%----------------------------------------------------
-module(client_sup).
-behaviour(supervisor).
-export([
        start_link/0
    ]).

-export([init/1]).


start_link()->
    supervisor:start_link({local, ?MODULE}, ?MODULE, [[]]).

init(_Arg)->%%startChild(LSOCK)哪里来的参数 
    {ok, {{simple_one_for_one, 10, 10},
            [{client, {client, start_link, []}, temporary, 1000, worker, [client]}]}}.
