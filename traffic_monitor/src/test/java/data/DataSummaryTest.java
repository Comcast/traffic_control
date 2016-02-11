package data;

import com.comcast.cdn.traffic_control.traffic_monitor.data.DataPoint;
import com.comcast.cdn.traffic_control.traffic_monitor.data.DataSummary;
import org.junit.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;

public class DataSummaryTest {
	@Test
	public void itReportsTheStartingAndEndValues() {
		DataSummary dataSummary = new DataSummary();
		assertThat(dataSummary.getStart(), equalTo((double) 0));
		assertThat(dataSummary.getEnd(), equalTo((double) 0));

		DataPoint dataPoint = new DataPoint("3.14", 100);
		dataSummary.record(dataPoint);

		assertThat(dataSummary.getStart(), equalTo(3.14));
		assertThat(dataSummary.getEnd(), equalTo(3.14));

		dataPoint = new DataPoint("2.67", 200);
		dataSummary.record(dataPoint);

		assertThat(dataSummary.getStart(), equalTo(3.14));
		assertThat(dataSummary.getEnd(), equalTo(2.67));
	}
}
