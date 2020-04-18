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
start(Sock) ->
    gen_server:start_link(?MODULE, [Sock], []).

init([_Sock]) ->
    Croom=#croom{},
    Client = #client{},
    %%接收到了服务端的套接字.
    %%进来默认在客厅
    %%检查用户是否已链接，已连接更换connid，断开原有Connid
    {ok, { Client,Croom}}.%%client客户连接表就是我们服务器的状态，有多少人。

handle_call(_Request, _From, { Client,Croom}) ->
    {noreply,{ Client,Croom}}.
%%因为我们是服务端客户端连接没有直接进程所以call、cast暂时用不上

handle_cast(_Msg, { Client,Croom}) ->
    {noreply, { Client,Croom}}.


handle_info({tcp_closed,Socket},{Client,Croom})->
        io:format("~n SOCKET ~p  CLOSED ~n",[Socket]),
	{noreply,{ Client,Croom}};

handle_info({tcp,From,Msg1},{ Client,Croom}) ->
    [H|T]=binary_to_term(Msg1),
        case H of
	login->%%检查是否已经登录
	    P=ets:lookup(client,T),
	    case P of
		[]->
		    [{_,_,_,L_OldMemberList}]=ets:lookup(croom,livingroom),
		    ets:insert(client,Client#client{id=T,socket=From,status=yes,location=livingroom}),
		    gen_tcp:send(From,term_to_binary([success|T])),
		    %%返回用户名
		    io:format("~n oldmemberlist ~p ~n",[L_OldMemberList]),
		    L_NewMemberList=lists:merge(L_OldMemberList,[T]),
		    io:format("~n newmemberlist ~p ~n",[L_NewMemberList]),
		    io:format("NewMemberlist~p ~n",[L_NewMemberList]),
		    ets:update_element(croom,livingroom,{4,L_NewMemberList}),
	   	    {noreply,{Client,Croom}};
		[{_,_,_,_,_,_,_}]->
		    gen_tcp:send(From,term_to_binary([fail|"you already login in!"])),
		    {noreply,{ Client,Croom}}
		    %%返回你已经登录的信息。
	    end;
	send->
	    [H1|T1]=T,
	    io:format("~n receive message from ~p:~p ~n",[H1,T1]),
	    %%遍历列表然后一个个发送过去给客户端.
	    [{_,_,_,_,_,_,S_Location0}] = ets:lookup(client,H1),
	    S_UL=ets:tab2list(client),
	    lists:map(fun(X)->
			  {_,_,_,To,_,_,S_Location}=X,
		          case S_Location of
		              S_Location0->
				  gen_tcp:send(To,term_to_binary([recMsg|T]));
			      _S_Location1->
				  io:format("not in the same room")
			  end
		      end,
	              S_UL),
	    {noreply,{ Client,Croom}};
	cRoom->
	    %%检查房间是否存在，不存在则创建。
	    [T1,T2]=T,
	    io:format("Croom T1 is ~p ~n",[T1]),
	    io:format("Croom T2 is ~p ~n",[T2]),
	    case ets:lookup(croom,T2) of
		[{_,_,_}]->%%查找是否存在该房间
		    gen_tcp:send(From,term_to_binary([fail|T2]));
		[]->
		    [{_,_,_,_,_,_,C_OldRoom}]=ets:lookup(client,T1),
		    %%创建房间,更改旧房间成员记录，更新新房间成员记录。
		    [{_,_,_,C_OldmemberList}]=ets:lookup(croom,C_OldRoom),
		    C_NewmemberList=lists:delete(T1,C_OldmemberList),
		    ets:update_element(croom,C_OldRoom,{4,C_NewmemberList}),
	            case  C_NewmemberList of
		         []->
		             case C_OldRoom of
			         livingroom->
                                     io:format("");
				 _Else->
				     io:format("running!!!!!!!~n"),					                         ets:delete(croom,C_OldRoom)
		             end;
		          _Else->
			    io:format("")
		    end,
		    ets:insert(croom,#croom{name=T2,status=open,memberList=[T1]}),
		    ets:update_element(client,T1,{7,T2}),                    
                    gen_tcp:send(From,term_to_binary([success|T2]))
	    end, 
	    {noreply,{ Client,Croom}};
         rls->
             RLS=ets:tab2list(croom),
	     gen_tcp:send(From,term_to_binary([RLS])),
	     {noreply,{ Client,Croom}};
	 goIn->
	    %%同理，先删除原先房间的成员名单，然后再进入新房间，逻辑同上，之后检查房间还有没有人，没人就删了。
	    [G_UN,G_RN]=T,
            [{_,_,_,_,_,_,G_CheckLocation}]=ets:lookup(client,G_UN), 
	    case ets:lookup(croom,G_RN) of%%查找这个RN房间的信息。
	    [{_,_,_,_}]->%%这个房间存在。
		     case G_CheckLocation of
			    G_RN->%%已经在这个房间。
			        gen_tcp:send(From,term_to_binary([fail1|G_RN]));
			    _G_RN1->%%不在这个房间。
			        [{_,_,_,_,_,_,G_OldRoom}]=ets:lookup(client,G_UN),
		                %%创建房间,更改旧房间成员记录，更新新房间成员记录。
		                [{_,_,_,G_OldmemberList}]=ets:lookup(croom,G_OldRoom),
		                G_NewmemberList=lists:delete(G_UN,G_OldmemberList),%%与ETS参数相反方向。
				ets:update_element(croom,G_OldRoom,{4,G_NewmemberList}),
				case  G_NewmemberList of
				    []->
					case G_OldRoom of
					    livingroom->
                                                io:format("");
					    _G_Else->
						io:format("running!!!!!!!~n"),					                        ets:delete(croom,G_OldRoom)
				        end;
				    _G_Else->
					 io:format("")
				end,
				%%更新新房
				[{_,_,_,G_NewRoomMListOld}]=ets:lookup(croom,G_RN),
				G_NewRoomMList=lists:merge(G_NewRoomMListOld,[G_UN]),
                                ets:update_element(croom,G_RN,{4,G_NewRoomMList}),  
                 	        ets:update_element(client,G_UN,{7,G_RN}),
		                gen_tcp:send(From,term_to_binary([success,G_RN]))
		     end;    
             _Void->
                      gen_tcp:send(From,term_to_binary([fail,G_RN]))
             end,
	     {noreply,{ Client,Croom}};
	 memberList->
		[M_User]=T,
		[{_,_,_,_,_,_,M_UserLocation}]=ets:lookup(client,M_User),
	        [{_,_,_,M_FinalList}]=ets:lookup(croom,M_UserLocation),
		gen_tcp:send(From,term_to_binary([M_UserLocation,M_FinalList])),
                {noreply,{Client,Croom}};
		%%gen_tcp:send(From,term_to_binary([UserLocation])),--循环传值接受无效，所以重新做功能，再croom里面加入成员列表。
		%%最终返回的在一个房间里人的列表
                %%lists:map(fun(X)->
			  %%{_,MName,_,_,_,_,Location}=X,
		              %%case Location of
		                  %%UserLocation->
				      %%io:format("~n sending MName is ~p ~n",[MName]),
				      %%gen_tcp:send(From,term_to_binary(MName));
				     %% io:format("state1~p ~n",[MemberList#memberList.userName]),
				      %%io:format("mname~p ~n",[MName]),
				     %% MemberList#memberList{userName=lists:merge(MemberList#memberList.userName,[MName])},				  %%_UserLocation1->
                                      %%io:format("~n ~p is not here ~n",[MName])
			      %%end%%找到了两个
		          %%end,
	              %%ets:tab2list(client)),
		%%io:format("endend~n"),%%不加这一行不走下一行。
		%%gen_tcp:send(From,term_to_binary(endML)),
		%%io:format("~n test2 ~p ~n",[MemberList#memberList.userName]),
		%%gen_tcp:send(From,term_to_binary(MemberList#memberList.userName)),
		%%io:format("ending 1~n"),
	    p2p->
		[P_UserName,P_Message,From_User]=T,
                [{_,_,_,From_Sock,_,_,From_Location}]=ets:lookup(client,From_User),
		case ets:lookup(client,P_UserName) of
                    []->
			gen_tcp:send(From_Sock,term_to_binary([recPMsg,fail1,P_UserName])),
			{noreply,{ Client,Croom}};
		    [{_,_,_,_,_,_,_}]->
			[{_,_,_,P_Sock,_,_,P_Location}]=ets:lookup(client,P_UserName),
			case From_Location of
			    P_Location->%%同房间发送成功
				gen_tcp:send(P_Sock,term_to_binary([recPMsg,success,From_User,P_Message])),
				{noreply,{ Client,Croom}};
			_Else_P_Location->%%不同房间发送失败。
                                gen_tcp:send(From_Sock,term_to_binary([recPMsg,fail,P_UserName])),
		                {noreply,{ Client,Croom}}
           		end
		end;
	    quit->
		io:format("~n receive quit username ~p ~n",[T]),
		ets:delete(client,T),
		io:format("~n already delete ~n"),
		{stop, normal, { Client,Croom}}
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
