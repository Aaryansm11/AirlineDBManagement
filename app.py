import streamlit as st
import pymysql

# Database connection
def get_connection():
    return pymysql.connect(
        host='localhost',
        user='root',
        password='Vaaryan112659@',
        database='AirlineDB',
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )

# Function to book a seat
def book_seat(flight_id, passenger_id, seat_number):
    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            # Insert booking record
            sql = """
            INSERT INTO Booking (flight_id, passenger_id, seat_number)
            VALUES (%s, %s, %s)
            """
            cursor.execute(sql, (flight_id, passenger_id, seat_number))
            connection.commit()
            return "Booking successful!"
    except Exception as e:
        return f"Error: {e}"
    finally:
        connection.close()

# Function to cancel a booking
def cancel_booking(booking_id):
    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            # Delete booking record
            sql = "DELETE FROM Booking WHERE booking_id = %s"
            cursor.execute(sql, (booking_id,))
            connection.commit()
            return "Booking cancelled successfully!"
    except Exception as e:
        return f"Error: {e}"
    finally:
        connection.close()

# Function to view seat allocation
def view_seat_allocation(flight_id):
    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            sql = """
            SELECT seat_number, status, last_updated
            FROM Seat_Allocation
            WHERE flight_id = %s
            """
            cursor.execute(sql, (flight_id,))
            result = cursor.fetchall()
            return result
    except Exception as e:
        return f"Error: {e}"
    finally:
        connection.close()

# Streamlit App UI
st.title("Airline Booking System")

# Tabs for different actions
tab1, tab2, tab3 = st.tabs(["Book a Seat", "Cancel a Booking", "View Seat Allocation"])

with tab1:
    st.header("Book a Seat")
    flight_id = st.number_input("Flight ID", min_value=1, step=1)
    passenger_id = st.number_input("Passenger ID", min_value=1, step=1)
    seat_number = st.text_input("Seat Number")

    if st.button("Book Seat"):
        if flight_id and passenger_id and seat_number:
            message = book_seat(flight_id, passenger_id, seat_number)
            st.success(message)
        else:
            st.error("Please fill in all fields.")

with tab2:
    st.header("Cancel a Booking")
    booking_id = st.number_input("Booking ID", min_value=1, step=1)

    if st.button("Cancel Booking"):
        if booking_id:
            message = cancel_booking(booking_id)
            st.success(message)
        else:
            st.error("Please enter a Booking ID.")

with tab3:
    st.header("View Seat Allocation")
    flight_id_view = st.number_input("Flight ID for Seat Allocation", min_value=1, step=1)

    if st.button("View Seats"):
        if flight_id_view:
            seats = view_seat_allocation(flight_id_view)
            if seats:
                st.table(seats)
            else:
                st.error("No data found for this flight.")
        else:
            st.error("Please enter a Flight ID.")
