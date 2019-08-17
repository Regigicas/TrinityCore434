/*
* Copyright (C) 2008-2014 TrinityCore <http://www.trinitycore.org/>
*
* This program is free software; you can redistribute it and/or modify it
* under the terms of the GNU General Public License as published by the
* Free Software Foundation; either version 2 of the License, or (at your
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
* more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef __ASYNCACCEPT_H_
#define __ASYNCACCEPT_H_

#include "IoContext.h"
#include "IpAddress.h"
#include "Log.h"
#include <boost/asio/ip/tcp.hpp>
#include <functional>
#include <atomic>

using boost::asio::ip::tcp;

#if BOOST_VERSION >= 106600
#define TRINITY_MAX_LISTEN_CONNECTIONS boost::asio::socket_base::max_listen_connections
#else
#define TRINITY_MAX_LISTEN_CONNECTIONS boost::asio::socket_base::max_connections
#endif

class AsyncAcceptor
{
public:
    typedef void(*ManagerAcceptHandler)(tcp::socket&& newSocket);

    AsyncAcceptor(Trinity::Asio::IoContext& ioContext, std::string const& bindIp, uint16 port) :
        _acceptor(ioContext, tcp::endpoint(Trinity::Net::make_address(bindIp), port)),
        _socket(ioContext)
    {
    }

    template <class T>
    void AsyncAccept();

    void AsyncAcceptManaged(ManagerAcceptHandler mgrHandler)
    {
        _acceptor.async_accept(_socket, [this, mgrHandler](boost::system::error_code error)
        {
            if (!error)
            {
                try
                {
                    _socket.non_blocking(true);

                    mgrHandler(std::move(_socket));
                }
                catch (boost::system::system_error const& err)
                {
                    TC_LOG_INFO("network", "Failed to initialize client's socket %s", err.what());
                }
            }

            AsyncAcceptManaged(mgrHandler);
        });
    }

private:
    tcp::acceptor _acceptor;
    tcp::socket _socket;
};

template<class T>
void AsyncAcceptor::AsyncAccept()
{
    _acceptor.async_accept(_socket, [this](boost::system::error_code error)
    {
        if (!error)
        {
            try
            {
                // this-> is required here to fix an segmentation fault in gcc 4.7.2 - reason is lambdas in a templated class
                std::make_shared<T>(std::move(this->_socket))->Start();
            }
            catch (boost::system::system_error const& err)
            {
                TC_LOG_INFO("network", "Failed to retrieve client's remote address %s", err.what());
            }
        }

        // lets slap some more this-> on this so we can fix this bug with gcc 4.7.2 throwing internals in yo face
        this->AsyncAccept<T>();
    });
}

#endif /* __ASYNCACCEPT_H_ */
