-module(room).
-behavior(gen_server).
-export([]).
-export([start/1,init/1,handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("client.hrl").
-include("croom.hrl").
-include("user1.hrl").



start(RoomName)->
    gen_server:start_link(?MODULE,[RoomName],[]).

%%创建房间进程。
init([RoomName])->
    Room=#croom{name=RoomName,roomId =self(),memberList=[]},
    ets:insert(croom,Room),
    {ok,Room}.

handle_call(_Request, _From,Room) ->%%--会timeout，超时等不到回复。
    {noreply,Room}.

handle_cast({p2p,From_User,P_Sock,P_Message},Room)->
	gen_tcp:send(P_Sock,term_to_binary([recPMsg,From_User,P_Message])),
	{noreply,Room};


handle_cast({send,User,Msg},Room)->
	io:format("~n ets:lookup(croom,croom,Room#croom.name) ~p ~n",[ets:lookup(croom,Room#croom.name)]),
	[{_,_,_,CurrentUser}]=ets:lookup(croom,Room#croom.name),
	Send_User_Msg=[User|Msg],
	lists:map(fun(X)->
		[{_,_,_,To,_,_,_}]=ets:lookup(userList,X),
		gen_tcp:send(To,term_to_binary([recMsg|Send_User_Msg]))
						end
	,CurrentUser),
	{noreply,Room};

handle_cast({goIn,UserName},Room)->
	[{_,_,_,_,_,_,OldRoom}]=ets:lookup(userList,UserName),
	case ets:lookup(croom,OldRoom) of
		[{_,_,_,OldRoom_Member}]->%%进入过房间的
			New_OldRoom_Member=lists:delete(UserName,OldRoom_Member),
			case New_OldRoom_Member of%%升级旧房间
				[]->
					case OldRoom of
						livingroom->
							io:format("do nothing with livingroom");
						_Else->
							ets:delete(croom,OldRoom)
					end;
				_Else->
					ets:update_element(croom,OldRoom,{4,New_OldRoom_Member})
			end;
		[]->%%刚登陆进来的
			io:format("do nothing first time")
	end,
	  %%升级新房间
    [{_,_,_,GoIn_MemberList}]=ets:lookup(croom,Room#croom.name),
    New_GoIn_MemberList=lists:merge(GoIn_MemberList,[UserName]),
	  ets:update_element(userList,UserName,{7,Room#croom.name}),%%更新用户位置
    ets:update_element(croom,Room#croom.name,{4,New_GoIn_MemberList}),
    {noreply,Room}.

handle_info(_Info,State)->
    {noreply,State}.
terminate(_Reason,_State)->
    ok.
code_change(_OldVsn,State,_Extra)->
    {ok,State}.
