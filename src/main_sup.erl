%%----------------------------------------------------
%% @doc 节点监控树
%% 
%% @author Jangee@qq.com
%% @end
%%----------------------------------------------------
-module(main_sup).
-behaviour(supervisor).
-export([
        start_link/0
        ,init/1
    ]).

-include("common.hrl").

%%----------------------------------------------------
%% OTP APIS
%%----------------------------------------------------
start_link()->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {ok, {{one_for_one, 10, 10},
            [
                {client_sup, {client_sup, start_link, []}, temporary, 1000, worker, [client_sup]}
                ,{client_mgr, {client_mgr, start_link, []}, temporary, 1000, worker, [client_mgr]}
            ]
        }
    }.

