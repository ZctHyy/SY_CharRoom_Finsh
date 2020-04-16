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

init([Sock]) ->
    Client = #client{socket = Sock,location=livingroom},
    %%接收到了服务端的套接字.
    %%进来默认在客厅
    %%检查用户是否已链接，已连接更换connid，断开原有Connid
    ets:insert(client, Client),
    {ok, Client}.%%client客户连接表就是我们服务器的状态，有多少人。

handle_call(_Request, _From, Client) ->
    {noreply, Client}.
%%因为我们是服务端客户端连接没有直接进程所以call、cast暂时用不上

handle_cast(_Msg, Client) ->
    {noreply, Client}.

handle_info({tcp,From,Msg1},Client) ->
    [H|T]=binary_to_term(Msg1),
        case H of
	login->%%检查是否已经登录
	    P=ets:lookup(client,T),
	    case P of
		[]->
		    ets:insert(client,Client#client{id=T,socket=From,status=yes}),
	            gen_tcp:send(From,term_to_binary([success|T])),
		    %%返回用户名
	   	    {noreply,Client};
		[{_,_,_,_,_,_,_}]->
		    gen_tcp:send(From,term_to_binary([fail|"you already login in!"])),
		    {noreply,Client}
		    %%返回你已经登录的信息。
	    end;
	send->
	    [H1|T1]=T,
	    io:format("~n receive message from ~p:~p ~n",[H1,T1]),
	    %%遍历列表然后一个个发送过去给客户端.
	    [{_,_,_,_,_,_,Location0}] = ets:lookup(client,H1),
	    UL=ets:tab2list(client),
	    lists:map(fun(X)->
			  {_,_,_,To,_,_,Location}=X,
		          case Location of
		              Location0->
				  gen_tcp:send(To,term_to_binary([recMsg|T]))
			  end
		      end,
	              UL),
	    {noreply,Client};
	cRoom->
	    %%检查房间是否存在，不存在则创建。
	    case ets:lookup(croom,T) of
		[{_,_,_}]->
		    gen_tcp:send(From,term_to_binary([fail|T]));
		[]->
		    %%创建房间
          	    ets:insert(croom,#croom{name=T,status=open}),
		    gen_tcp:send(From,term_to_binary([success|T]))
	    end, 
	    {noreply,Client};
         rls->
             RLS=ets:tab2list(croom),
	     gen_tcp:send(From,term_to_binary([RLS])),
	     {noreply,Client};
	 goIn->
	     [UN|RN]=T,
             CheckRN=ets:lookup(croom,RN),
	     case CheckRN of
		 [{_,_,_}]->
		     ets:delete(client,UN),
		     ets:insert(client,#client{id=UN,socket=From,status=yes,location=RN}),
		     gen_tcp:send(From,term_to_binary([success|RN]));
                 []->
                      gen_tcp:send(From,term_to_binary([fail|RN]))
             end,
	     {noreply,Client}
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
