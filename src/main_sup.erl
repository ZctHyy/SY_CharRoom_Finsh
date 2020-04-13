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
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).%%当前模块？MODULE,调用运行supervisor模块下的start_link函数。并且调用自己的Init函数.,必须返回的是{ok，State}.

init([]) ->
    {ok, {{one_for_one, 10, 10},%%重启策略原子，选择重启策略，然后是最大重启次数和时间限制，即，如果一个监控器10s内重启超过10次，%%那么监控器则终止所有工作并退出
            [%%描述如何启动各个工作进程的元组。worker的启动格式。
                {client_sup, {client_sup, start_link, []}, temporary, 1000, worker, [client_sup]}
                ,{client_mgr, {client_mgr, start_link, []}, temporary, 1000, worker, [client_mgr]}
             %%client_sup标签。
		%%后面的元组是启动的函数。
		%%进程是否重启，permanent，进程总是重启，transient非正常值重启，temporary不重启。
		%%监控进程类型，worker或者supervisor
		%%回调模块名        
	    ]
        }
    }.

