%%----------------------------------------------------
%% @doc
%% 客户端模拟器
%% @author Raydraw@163.com
%% @end
%%----------------------------------------------------
-module(tester).
-behaviour(gen_server).
-export([start_link/0,start/0]).
-export([init/1,login/1,speak/1,cRoom/1,goIn/1,roomList/0, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {socket,login,un}).%%记录了socket，登录状态，用户名
-define(Port,8100).

start_link() ->
gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

start() ->
gen_server:start({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    State = #state{login=no},
    gen_server:cast(self(),connect),%%自己跑起自己的套接字。
    {ok, State}.

handle_call(_Request, _From, State) ->
    {noreply, State}.

%%与套接字有关，客户端想要连接服务端就要使用一个套接字，标识自己的地址。
handle_cast(connect , State) ->
    {ok,Socket } = gen_tcp:connect("127.0.0.1",?Port , [binary]),
    {noreply, State#state{socket = Socket}};
%%更改变量名State记录，并设置值为Socket,这个状态保存了连接服务端的方法。
%%此处设置发送消息的类型为binary

handle_cast({goIn,RoomName1},State)->
    case State#state.login of
	yes->
	    gen_tcp:send(State#state.socket,term_to_binary([goIn|[State#state.un|RoomName1]])),
	    receive
                {tcp,_Server,Response}->
                    [GoInResult|GoInName]=Response,
		    case GoInResult of
		        success->
			    io:format("~n success get in ~p ~n",[GoInName]);
			fail->
			    io:format("~n fail,please check the Room ~p exist or not",[GoInName]) 
		    end	
	    end,
	    {noreply,State};
	no->
	    io:format("please login first~n",[]),
	    {noreply,State}
    end;

handle_cast({rls},State)->
    case State#state.login of
	yes->
	    gen_tcp:send(State#state.socket,term_to_binary([rls])),
	    receive
                {tcp,_Server,Response}->
                    io:format("~n room list:~p ~n",binary_to_term(Response))
	    end,
	    {noreply,State};
	no->
	    io:format("please login first~n",[]),
	    {noreply,State}
    end;

handle_cast({c_Room,RoomName},State)->
    %%创建房间的方法
    %%跟服务端说我要建房
    case State#state.login of
	yes->
             gen_tcp:send(State#state.socket,term_to_binary([cRoom|RoomName])),
             receive
	        {tcp,_Server,Response}->
                [Cresult|CT]=binary_to_term(Response),
	        case Cresult of
	       	    success->
		        io:format("~n create room ~p,room name is ~p ~n",[Cresult,CT]),
	                {noreply,State};
		    fail->
                        io:format("~n create room ~p,room ~p is already exist",[Cresult,CT]),
	            {noreply,State}
                end
	     end;
	no->
            io:format("please login first~n",[]),
            {noreply,State}
   end;

handle_cast({send,Msg},State) -> 
    %%发送信息方法
    %%修改State映射为state.socket值。
    Login=State#state.login,
    Un=State#state.un,
    UM=[Un|Msg],
    case Login of
	yes->
	    Msg1=term_to_binary([send|UM]),
            gen_tcp:send(State#state.socket,Msg1),
	    {noreply,State};
	%%用自己的套接字然后发送出去.送的类型一定是规定好的binary或者别的。
	no->
	    io:format("please log in first ~n"),
	    {noreply,State}
    end;
    
handle_cast({login,UserName},State)->%%登录方法
    io:format("logining ~n"),
    gen_tcp:send(State#state.socket,term_to_binary([login|UserName])),
    receive
	{tcp,_Server,Response}->
	    [Result|Rs]=binary_to_term(Response),
	    case Result of
		success->
	            io:format("success!Your UserName is :~p ~n",[Rs]),
			{noreply,State#state{login = yes,un = Rs}};
		fail->
		    io:format("fail! ~p~n",[Rs]),
		    {noreply,State}
	    end
    end;
    
handle_cast({json,Msg}, State) ->
    NMsg = json:encode({struct,Msg}),
    gen_tcp:send(State#state.socket,NMsg),
    {noreply,State}.

handle_info({tcp,_From,RMsg}, State) ->
    %%因为我们没有调用call或者cast，tcp发送过来直接就是信息
    %%所以我们用万能info处理问题。
    [RH|RT]=binary_to_term(RMsg),
    case RH of%%RecevieHead，ReceiveTill
	recMsg->
	    [FU|RM]=RT,%%FU，FromUser，RM，RecevieMessage
	    io:format("from: ~p:~p ~n ",[FU,RM]),
	    {noreply,State};
	true->
            {noreply,State}
    end; 
        
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%登录接口
login(UserName)->
    gen_server:cast(?MODULE,{login,UserName}).
%%说话接口
speak(Msg)->
    gen_server:cast(?MODULE,{send,Msg}).
%%建房接口
cRoom(RoomName)->
    gen_server:cast(?MODULE,{c_Room,RoomName}).
%%房表接口
roomList()->
    gen_server:cast(?MODULE,{rls}).
%%进入房间接口--TODO
goIn(RoomName1)->
    gen_server:cast(?MODULE,{goIn,RoomName1}).
%%因为我们是服务端客户端连接没有直接进程所以call、cast暂时用不上    

