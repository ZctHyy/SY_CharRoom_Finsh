%%----------------------------------------------------
%% @doc 常用方法
%% 
%% @author Jangee@qq.com
%% @end
%%----------------------------------------------------
-module(util).
-export([
        u/1
    ]).

-include("common.hrl").


%% 重载模块
u([]) ->
    ok;
u([H | T]) ->
    u(H),
    u(T);
u(Mod) ->
    code:soft_purge(Mod),
    code:load_file(Mod).

    
