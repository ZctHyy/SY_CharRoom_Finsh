%%----------------------------------------------------
%% @doc 服务器启动器
%% 
%% @author Jangee@qq.com
%% @end
%%----------------------------------------------------
-module(main).
-behaviour(application).
-export([
        start/0
        ,start/2
        ,stop/1
]).

start() ->
    application:start(crypto),
    application:start(main).

%%----------------------------------------------------
%% otp apis
%%----------------------------------------------------

%% @doc init
start(_Type, _Args) ->
    main_sup:start_link().

%% @doc stop system
stop(_State) ->
    ok.
