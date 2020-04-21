-module(room_manager).
-behavior(gen_server).
-export([memberList/1,c_Room/2, goIn/2,roomList/0,send/2]).
-export([start_link/0,init/1,handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("client.hrl").
-include("croom.hrl").
-include("user1.hrl").
-record(roomState, {roomId,roomName}).%%定义记录房间进程的id，房间名

p2p(P_UserName,P_Message,From_User)->
  [{_,_,_,_,_,_,From_Location}]=ets:lookup(userList,From_User),
  [{_,RoomPid,_}]=ets:lookup(room_State,From_Location),
  case ets:lookup(userList,P_UserName) of
    []->
      fail;
    [{_,_,_,P_Sock,_,_,P_Location}]->
      case From_Location of
        P_Location->%%同房间发送成功
          gen_server:cast(RoomPid,{p2p,From_User,P_Sock,P_Message}),
          {success,From_User,P_UserName,P_Message};
        _Else_P_Location->%%不同房间发送失败。
         fail
      end
  end.



send(User,Msg)->
  [{_,_,_,_,_,_,User_Location}]=ets:lookup(userList,User),
  [{_,RoomId,_}]=ets:lookup(room_State,User_Location),
  gen_server:cast(RoomId,{send,User,Msg}).

c_Room(RoomName,C_Room_UserName)->
   case ets:lookup(croom,RoomName) of
       [{_,_,_,_}]->%%存在该房
          fail;
       []->
         case room:start(RoomName) of
           {ok,Room}->
             io:format("~n Room is ~p ~n",[Room]),
             ets:insert(room_State,#roomState{roomId=Room,roomName=RoomName}),
             io:format("room_State t2l ~p ~n",[ets:tab2list(room_State)]),
             goIn(RoomName,C_Room_UserName),
             success;
           _Else->
             fail1
         end
   end.
    

goIn(Go_RoomName,Go_UserName)->
  [{_,_,_,_,_,_,CurLocation}]=ets:lookup(userList,Go_UserName),
  case CurLocation of
    Go_RoomName->
      fail1;
    _Else->
      io:format("~nrunning eles1!!!~p ~n ",[ets:lookup(room_State,Go_RoomName)]),
      case ets:lookup(room_State,Go_RoomName) of
        [{_,RoomPID,_}]->%%有这个房间
          io:format("~n roomname ~p, id ~p ~n",[Go_RoomName,RoomPID]),
          gen_server:cast(RoomPID,{goIn,Go_UserName}),
          success;
        []->
          fail
      end
  end.

roomList()->
  RLS=ets:tab2list(croom),
  [X||{_,X,_,_}<-RLS].

memberList(UserName)->
  [{_,_,_,_,_,_,M_UserLocation}]=ets:lookup(userList,UserName),
  [MemberList]=[X||{_,_,_,X}<-ets:lookup(croom,M_UserLocation)],
  {M_UserLocation,MemberList}.



start_link()->
  gen_server:start_link(?MODULE,[],[]).
init([])->
    ets:new(room_State,[set, named_table, public,  {keypos, #roomState.roomName}]),
    ets:new(croom, [set, named_table, public,  {keypos, #croom.name}]),
    {ok,LivingRoom_ID}=room:start(livingroom),
    ets:insert(room_State,#roomState{roomId=LivingRoom_ID,roomName=livingroom}),
    io:format("LivingRoom_ID ~p ~n",[ets:tab2list(room_State)]),
    {ok,#roomState{}}.
handle_call(_Request, _From,State) ->%%--会timeout，超时等不到回复。
    {noreply,State}.
handle_cast(_Msg,State)->
    {noreply,State}.
handle_info(_Info,State)->
    {noreply,State}.
terminate(_Reason,_State)->
    ok.
code_change(_OldVsn,State,_Extra)->
    {ok,State}.

