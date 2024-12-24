import tkinter as tk
from tkinter import messagebox, simpledialog, ttk
import psycopg2

class portException(Exception): pass

def ask_port():
    """
        ask for a valid TCP port
        ask_port :: () -> Integer | Exception
    """
    port = simpledialog.askinteger("Input", "TCP port number:")
    if port is None:
        raise portException("Port input cancelled")
    if (port < 1024) or (port > 65535):
        raise portException("Invalid port number")
    return port

def ask_conn_parameters():
    """
        ask_conn_parameters:: () -> (Integer, String, String, String)
        pide los parámetros de conexión
    """
    port = ask_port()
    
    user = simpledialog.askstring("Input", "Usuario:")
    if user is None:
        raise portException("User input cancelled")
    
    password = simpledialog.askstring("Input", "Contraseña:", show='*')
    if password is None:
        raise portException("Password input cancelled")
    
    database = simpledialog.askstring("Input", "Base de datos:")
    if database is None:
        raise portException("Database input cancelled")
    
    return (port, user, password, database)

def execute_query(cur, query, tree):
    try:
        cur.execute(query)
        records = cur.fetchall()
        columns = [desc[0] for desc in cur.description]
        
        tree["columns"] = columns
        for col in columns:
            tree.heading(col, text=col, anchor=tk.CENTER)
            tree.column(col, anchor=tk.CENTER, width=150)
        
        for i in tree.get_children():
            tree.delete(i)
        
        for record in records:
            tree.insert("", "end", values=record)
    except psycopg2.Error as e:
        messagebox.showerror("Database error", f"Database error: {e}")

def connect_and_query():
    try:
        (port, user, password, database) = ask_conn_parameters()
        connstring = f'host=localhost port={port} user={user} password={password} dbname={database}'
        conn = psycopg2.connect(connstring)
        cur = conn.cursor()

        def on_query():
            query_window = tk.Toplevel(root)
            query_window.title("Input")
            query_window.geometry("800x600")  # Ajusta el tamaño de la ventana aquí

            tk.Label(query_window, text="Consulta (escribe 'exit' para salir):").pack(pady=10)
            query_text = tk.Text(query_window, width=100, height=30)  # Ajusta el tamaño del cuadro de entrada aquí
            query_text.pack(pady=10, fill=tk.BOTH, expand=True)

            def submit_query():
                query = query_text.get("1.0", tk.END).strip()
                if query.lower() == 'exit':
                    root.quit()
                else:
                    execute_query(cur, query, tree)
                query_window.destroy()

            submit_button = tk.Button(query_window, text="Ejecutar", command=submit_query)
            submit_button.pack(pady=10)

        query_button = tk.Button(root, text="Ejecutar Consulta", command=on_query)
        query_button.pack(pady=10)

        close_button = tk.Button(root, text="Cerrar", command=root.quit)
        close_button.pack(pady=10)

        root.mainloop()

        cur.close()
        conn.close()
    except portException as e:
        messagebox.showerror("Port error", str(e))
    except KeyboardInterrupt:
        messagebox.showinfo("Interrupted", "Program interrupted by user.")
    except psycopg2.Error as e:
        messagebox.showerror("Database error", f"Database error: {e}")

def main():
    global root, tree
    root = tk.Tk()
    root.title("Database Query Interface")
    root.geometry("1200x700")  # Ajusta el tamaño de la ventana principal

    tree = ttk.Treeview(root, show='headings')
    tree.pack(padx=10, pady=10, fill=tk.BOTH, expand=True)

    connect_and_query()

if __name__ == "__main__":
    main()
