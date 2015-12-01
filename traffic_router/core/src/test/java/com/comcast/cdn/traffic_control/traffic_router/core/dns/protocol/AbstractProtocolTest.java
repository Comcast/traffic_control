package com.comcast.cdn.traffic_control.traffic_router.core.dns.protocol;

import com.comcast.cdn.traffic_control.traffic_router.core.dns.DNSAccessEventBuilder;
import com.comcast.cdn.traffic_control.traffic_router.core.dns.DNSAccessRecord;
import com.comcast.cdn.traffic_control.traffic_router.core.dns.NameServer;
import org.apache.log4j.Logger;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mockito;
import org.powermock.core.classloader.annotations.PrepareForTest;
import org.powermock.modules.junit4.PowerMockRunner;
import org.xbill.DNS.*;

import java.net.Inet4Address;
import java.net.InetAddress;
import java.util.Random;

import static org.junit.Assert.fail;
import static org.mockito.Matchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.powermock.api.mockito.PowerMockito.*;


@RunWith(PowerMockRunner.class)
@PrepareForTest({AbstractProtocolTest.FakeAbstractProtocol.class, Logger.class, DNSAccessEventBuilder.class, Header.class, NameServer.class})
public class AbstractProtocolTest {
    private static Logger accessLogger = mock(Logger.class);
    private NameServer nameServer;
    private Header header;
    InetAddress client;

    @Before
    public void before() throws Exception {
        // force the xn field in the request
        Random random = mock(Random.class);
        Mockito.when(random.nextInt(0xffff)).thenReturn(65535);
        whenNew(Random.class).withNoArguments().thenReturn(random);

        mockStatic(System.class);
        when(System.currentTimeMillis()).thenReturn(144140678000L).thenReturn(144140678345L);

        mockStatic(Logger.class);
        when(Logger.getLogger("com.comcast.cdn.traffic_control.traffic_router.core.access")).thenReturn(accessLogger);

        header = new Header();
        header.setID(65535);
        header.setFlag(Flags.QR);

        client = Inet4Address.getByAddress(new byte[]{(byte) 192, (byte) 168, 23, 45});
        nameServer = mock(NameServer.class);
    }

    @Test
    public void itLogsARecordQueries() throws Exception {
        header.setRcode(Rcode.NOERROR);

        Name name = Name.fromString("www.example.com.");
        Record question = Record.newRecord(name, Type.A, DClass.IN, 12345L);
        Message query = Message.newQuery(question);

        query.getHeader().getRcode();

        byte[] queryBytes = query.toWire();

        whenNew(Message.class).withArguments(queryBytes).thenReturn(query);

        InetAddress resolvedAddress = Inet4Address.getByName("192.168.8.9");

        Record answer = new ARecord(name, DClass.IN, 12345L, resolvedAddress);
        Record[] answers = new Record[] {answer};

        Message response = mock(Message.class);
        when(response.getHeader()).thenReturn(header);
        when(response.getSectionArray(Section.ANSWER)).thenReturn(answers);
        when(response.getQuestion()).thenReturn(question);

        InetAddress client = Inet4Address.getByName("192.168.23.45");
        when(nameServer.query(any(Message.class), any(InetAddress.class), any(DNSAccessRecord.Builder.class))).thenReturn(response);

        FakeAbstractProtocol abstractProtocol = new FakeAbstractProtocol(client, queryBytes);
        abstractProtocol.setNameServer(nameServer);

        abstractProtocol.run();

        verify(accessLogger).info("144140678.000 qtype=DNS chi=192.168.23.45 ttms=345 xn=65535 fqdn=www.example.com. type=A class=IN ttl=12345 rcode=NOERROR rtype=- rloc=\"-\" rdtl=- rerr=\"-\" ans=\"192.168.8.9\"");
    }

    @Test
    public void itLogsOtherQueries() throws Exception {
        header.setRcode(Rcode.REFUSED);

        Name name = Name.fromString("John Wayne.");
        Record question = Record.newRecord(name, 65530, 43210);

        Message query = Message.newQuery(question);

        Message response = mock(Message.class);
        when(response.getHeader()).thenReturn(header);
        when(response.getSectionArray(Section.ANSWER)).thenReturn(null);
        when(response.getQuestion()).thenReturn(question);

        when(nameServer.query(any(Message.class), any(InetAddress.class), any(DNSAccessRecord.Builder.class))).thenReturn(response);

        FakeAbstractProtocol abstractProtocol = new FakeAbstractProtocol(client, query.toWire());
        abstractProtocol.setNameServer(nameServer);
        abstractProtocol.run();

        verify(accessLogger).info("144140678.000 qtype=DNS chi=192.168.23.45 ttms=345 xn=65535 fqdn=John\\032Wayne. type=TYPE65530 class=CLASS43210 ttl=0 rcode=REFUSED rtype=- rloc=\"-\" rdtl=- rerr=\"-\" ans=\"-\"");
    }

    @Test
    public void itLogsBadClientRequests() throws Exception {
        FakeAbstractProtocol abstractProtocol = new FakeAbstractProtocol(client, new byte[] {1,2,3,4,5,6,7});
        abstractProtocol.setNameServer(nameServer);
        abstractProtocol.run();
        verify(accessLogger).info("144140678.000 qtype=DNS chi=192.168.23.45 ttms=345 xn=- fqdn=- type=- class=- ttl=- rcode=- rtype=- rloc=\"-\" rdtl=- rerr=\"Bad Request:WireParseException:end of input\" ans=\"-\"");
    }

    @Test
    public void itLogsServerErrors() throws Exception {
        header.setRcode(Rcode.REFUSED);

        Name name = Name.fromString("John Wayne.");
        Record question = Record.newRecord(name, 65530, 43210);

        Message query = Message.newQuery(question);

        Message response = mock(Message.class);
        when(response.getHeader()).thenReturn(header);
        when(response.getSectionArray(Section.ANSWER)).thenReturn(null);
        when(response.getQuestion()).thenReturn(question);

        when(nameServer.query(any(Message.class), any(InetAddress.class), any(DNSAccessRecord.Builder.class))).thenThrow(new RuntimeException("Aw snap!"));

        FakeAbstractProtocol abstractProtocol = new FakeAbstractProtocol(client, query.toWire());
        abstractProtocol.setNameServer(nameServer);
        abstractProtocol.run();

        verify(accessLogger).info("144140678.000 qtype=DNS chi=192.168.23.45 ttms=345 xn=65535 fqdn=John\\032Wayne. type=TYPE65530 class=CLASS43210 ttl=0 rcode=SERVFAIL rtype=- rloc=\"-\" rdtl=- rerr=\"Server Error:RuntimeException:Aw snap!\" ans=\"-\"");

    }

    public class FakeAbstractProtocol extends AbstractProtocol {

        private final InetAddress inetAddress;
        private final byte[] request;

        public FakeAbstractProtocol(InetAddress inetAddress, byte[] request) {
            this.inetAddress = inetAddress;
            this.request = request;
        }

        @Override
        protected int getMaxResponseLength(Message request) {
            return Integer.MAX_VALUE;
        }

        @Override
        public void run() {
            try {
                query(inetAddress, request);
            } catch (WireParseException e) {
                // Ignore it
            }
        }

    }
}