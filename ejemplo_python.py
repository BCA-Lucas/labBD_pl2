import tkinter as tk
from tkinter import messagebox, simpledialog, ttk
import psycopg2

# Definición de una excepción personalizada para errores relacionados con el puerto
class portException(Exception): pass

# Función para solicitar al usuario un número de puerto válido
def ask_port():
    """
        ask for a valid TCP port
        ask_port :: () -> Integer | Exception
    """
    port = simpledialog.askinteger("Input", "TCP port number:")  # Solicita el número de puerto
    if port is None:  # Si el usuario cancela el cuadro de diálogo
        raise portException("Port input cancelled")
    if (port < 1024) or (port > 65535):  # Valida que el puerto esté en el rango permitido
        raise portException("Invalid port number")
    return port

# Función para solicitar al usuario los parámetros de conexión a la base de datos
def ask_conn_parameters():
    """
        ask_conn_parameters:: () -> (Integer, String, String, String)
        pide los parámetros de conexión
    """
    port = ask_port()  # Llama a la función para obtener el puerto
    
    user = simpledialog.askstring("Input", "Usuario:")  # Solicita el usuario
    if user is None:  # Valida si el usuario cancela
        raise portException("User input cancelled")
    
    password = simpledialog.askstring("Input", "Contraseña:", show='*')  # Solicita la contraseña de forma oculta
    if password is None:
        raise portException("Password input cancelled")
    
    database = simpledialog.askstring("Input", "Base de datos:")  # Solicita el nombre de la base de datos
    if database is None:
        raise portException("Database input cancelled")
    
    return (port, user, password, database)  # Retorna los parámetros

# Función para ejecutar una consulta y mostrar los resultados en un Treeview
def execute_query(cur, query, tree):
    try:
        cur.execute(query)  # Ejecuta la consulta en la base de datos
        records = cur.fetchall()  # Obtiene todos los resultados
        columns = [desc[0] for desc in cur.description]  # Obtiene los nombres de las columnas
        
        tree["columns"] = columns  # Configura las columnas en el Treeview
        for col in columns:  # Configura encabezados y anchos para cada columna
            tree.heading(col, text=col, anchor=tk.CENTER)
            tree.column(col, anchor=tk.CENTER, width=150)
        
        for i in tree.get_children():  # Limpia cualquier fila existente en el Treeview
            tree.delete(i)
        
        for record in records:  # Inserta los nuevos resultados
            tree.insert("", "end", values=record)
    except psycopg2.Error as e:
        messagebox.showerror("Database error", f"Database error: {e}")  # Muestra errores de la base de datos

# Función principal para conectar a la base de datos y manejar las consultas
def connect_and_query():
    try:
        (port, user, password, database) = ask_conn_parameters()  # Solicita parámetros de conexión
        connstring = f'host=localhost port={port} user={user} password={password} dbname={database}'  # Construye el string de conexión
        conn = psycopg2.connect(connstring)  # Establece la conexión
        cur = conn.cursor()

        # Función para manejar la entrada de consultas
        def on_query():
            query_window = tk.Toplevel(root)  # Crea una nueva ventana para la consulta
            query_window.title("Input")
            query_window.geometry("800x600")  # Ajusta el tamaño de la ventana

            tk.Label(query_window, text="Consulta (escribe 'exit' para salir):").pack(pady=10)
            query_text = tk.Text(query_window, width=100, height=30)  # Caja de texto para ingresar la consulta
            query_text.pack(pady=10, fill=tk.BOTH, expand=True)

            # Función para manejar la ejecución de la consulta
            def submit_query():
                query = query_text.get("1.0", tk.END).strip()  # Obtiene el texto ingresado
                if query.lower() == 'exit':  # Si el usuario ingresa 'exit', cierra la aplicación
                    root.quit()
                else:
                    execute_query(cur, query, tree)  # Ejecuta la consulta
                query_window.destroy()

            submit_button = tk.Button(query_window, text="Ejecutar", command=submit_query)  # Botón para ejecutar la consulta
            submit_button.pack(pady=10)

        # Botón para abrir la ventana de consulta
        query_button = tk.Button(root, text="Ejecutar Consulta", command=on_query)
        query_button.pack(pady=10)

        # Botón para cerrar la aplicación
        close_button = tk.Button(root, text="Cerrar", command=root.quit)
        close_button.pack(pady=10)

        root.mainloop()  # Inicia el bucle principal de la aplicación

        cur.close()  # Cierra el cursor
        conn.close()  # Cierra la conexión
    except portException as e:
        messagebox.showerror("Port error", str(e))  # Muestra errores relacionados con el puerto
    except KeyboardInterrupt:
        messagebox.showinfo("Interrupted", "Program interrupted by user.")  # Muestra un mensaje si se interrumpe el programa
    except psycopg2.Error as e:
        messagebox.showerror("Database error", f"Database error: {e}")  # Muestra errores de la base de datos

# Función principal para inicializar la interfaz
def main():
    global root, tree
    root = tk.Tk()
    root.title("Database Query Interface")
    root.geometry("1200x700")  # Ajusta el tamaño de la ventana principal

    tree = ttk.Treeview(root, show='headings')  # Crea un Treeview para mostrar resultados
    tree.pack(padx=10, pady=10, fill=tk.BOTH, expand=True)

    connect_and_query()  # Llama a la función principal para conectar y consultar

# Punto de entrada del programa
if __name__ == "__main__":
    main()
