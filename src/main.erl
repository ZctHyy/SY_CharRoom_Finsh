%%----------------------------------------------------
%% @doc 服务器启动器
%% 
%% @author Jangee@qq.com
%% @end
%%----------------------------------------------------
-module(main).
-behaviour(application).%%总是希望这一组模块，可以打包成一个应用，作为一个单独的整个，可以启动，停止.
			%%每一个应用都是通过application：start系列函数来启动，application:stop可以停止一个应用。 
			%%一个应用需要一个.app文件来描述，主要描述它包括哪些文件，参数等。 
			%%behaviour 类似于继承，所以可以到处start/2这种函数
-export([
        start/0
        ,start/2
        ,stop/1
]).

start() ->
    application:start(crypto),%%这是erlang的加密模块。
    application:start(main).%%这个是main.app,里面就是让运行main.erl模块，之后运行下面的start

%%----------------------------------------------------
%% otp apis
%%----------------------------------------------------

%% @doc init
start(_Type, _Args) ->%%运行main_sup的start_link函数
    main_sup:start_link().

%% @doc stop system
stop(_State) ->
    ok.
