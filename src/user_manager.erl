-module(user_manager).
-behavior(gen_server).
-export([login/1]).

-export([start_link/0,init/1,handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("common.hrl").
-include("croom.hrl").
-include("user1.hrl").

%%登陆方法
login({Login_From,Login_UserName})->
  Check_Login_UserName=ets:lookup(userList,Login_UserName),
	    case Check_Login_UserName of
        []->
          User=#user1{username=Login_UserName,socket=Login_From,status=yes},
          ets:insert(userList,User),
          case room_manager:goIn(livingroom,Login_UserName) of
            success->
              success;
            _Else->
              fail1
          end;
    		[{_,_,_,_,_,_,_}]->
          fail
      end.



%%默认函数
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
init([])->%%mgr的时候初始化.
    ets:new(userList,[set,public,named_table,{keypos,#user1.username}]),
    {ok,#user1{}}.
handle_call(_Request, _From,User) ->%%--会timeout，超时等不到回复。
    {noreply,User}.
handle_cast(_Msg,User)->
    {noreply,User}.
handle_info(_Info,User)->
    {noreply,User}.
terminate(_Reason,_User)->
    ok.
code_change(_OldVsn,User,_Extra)->
    {ok,User}.
