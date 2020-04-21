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
-include("croom.hrl").
-include("user1.hrl").

start(Sock) ->
    gen_server:start_link(?MODULE, [Sock], []).

init([Sock]) ->
    Client = #client{id=self(), pid=self(), socket = Sock, status=yes, time_info=calendar:local_time()},
    ets:insert(client,Client),    
    %%接收到了服务端的套接字.
    %%进来默认在客厅
    %%检查用户是否已链接，已连接更换connid，断开原有Connid
    {ok, Client}.%%client客户连接表就是我们服务器的状态，有多少人。


handle_call(_Request, _From,Client) ->%%--会timeout，超时等不到回复。
    {noreply,Client}.


handle_cast({login,Login_From,Login_UserName},Client)->
	case user_manager:login({Login_From,Login_UserName}) of
		success->
	     gen_tcp:send(Client#client.socket,term_to_binary([success,Login_UserName]));
		fail->
	     gen_tcp:send(Login_From,term_to_binary([fail,"you already login in!"]));
	 _Else->
	     io:format("running failure")
     end,
     {noreply,Client};

handle_cast({p2p,P_UserName,P_Message,From_User},Client)->
	room_manager:p2p();


handle_cast({send,Send_User,Send_Msg},Client)->
	room_manager:send(Send_User,Send_Msg),
	io:format("~n receive message from ~p:~p ~n",[Send_User,Send_Msg]),
	{noreply,Client};

handle_cast({cRoom,From,CRoom_User,CRoom_RoomName},Client)->
	case room_manager:c_Room(CRoom_RoomName,CRoom_User) of
		success->
			gen_tcp:send(From,term_to_binary([success|CRoom_RoomName]));
		fail->
			gen_tcp:send(From,term_to_binary([fail|CRoom_RoomName]));
		fail1->
			gen_tcp:send(From,term_to_binary([fail1]))
	end,
	{noreply,Client};

handle_cast({goIn,Go_UserName,Go_RoomName},Client)->
	case room_manager:goIn(Go_RoomName,Go_UserName) of
		success->
			gen_tcp:send(Client#client.socket,term_to_binary([success,Go_RoomName]));
		fail1->
			gen_tcp:send(Client#client.socket,term_to_binary([fail1|Go_RoomName]));
		fail->
			gen_tcp:send(Client#client.socket,term_to_binary([fail,Go_RoomName]))
	end,
	{noreply,Client};

handle_cast({rls},Client)->
	RoomList=room_manager:roomList(),
	gen_tcp:send(Client#client.socket,term_to_binary([RoomList])),
	{noreply,Client};

handle_cast({memberList,User},Client)->
	{Location,MemberListResult}=room_manager:memberList(User),
	gen_tcp:send(Client#client.socket,term_to_binary([Location,MemberListResult])),
	{noreply,Client}.

     
handle_info({tcp_closed,Socket},Client)->
	io:format("~n SOCKET ~p  CLOSED ~n",[Socket]),
	{noreply,Client};

handle_info({tcp,From,Msg1},Client) ->
    io:format("running login~n ~p",[Msg1]),
    [H|T]=binary_to_term(Msg1),
	case H of
		login->%%检查是否已经登录
			Login_UserName=T,
			gen_server:cast(self(),{login,From,Login_UserName}),
			{noreply,Client};
   	send->
	    [Send_User|Send_Msg]=T,
			gen_server:cast(self(),{send,Send_User,Send_Msg}),
	    {noreply,Client};
		cRoom-> %%检查房间是否存在，不存在则创建。
			[CRoom_User,CRoom_RoomName]=T,
			gen_server:cast(self(),{cRoom,From,CRoom_User,CRoom_RoomName}),
			{noreply,Client};
		rls->
			gen_server:cast(self(),{rls}),
			{noreply,Client};
		goIn->
	    %%同理，先删除原先房间的成员名单，然后再进入新房间，逻辑同上，之后检查房间还有没有人，没人就删了。
	    [G_UN,G_RN]=T,
	    gen_server:cast(self(),{goIn,From,G_UN,G_RN}),
	    {noreply,Client};
		memberList->
	    [M_User]=T,
	    gen_server:cast(self(),{memberList,M_User}),
	    {noreply,Client};
		p2p->
			[P_UserName,P_Message,From_User]=T,
			gen_server:cast(self(),{p2p,P_UserName,P_Message,From_User}),
	    {noreply,Client};
		quit->
	    io:format("~n receive quit username ~p ~n",[T]),
	    ets:delete(client,T),
	    io:format("~n already delete ~n"),
	    {stop, normal,Client}
	end.

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
