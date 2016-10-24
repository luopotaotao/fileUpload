package tt.model;

import java.util.LinkedList;
import java.util.List;

/**
 * Created by taotao on 2016/10/8.
 */
public class Clazz {
    private Integer id;
    private String name;
    private List<Student> students=new LinkedList<>();

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public List<Student> getStudents() {
        return students;
    }

    public void setStudents(List<Student> students) {
        this.students = students;
    }

    @Override
    public String toString() {
        return "Clazz{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", students=" + students +
                '}';
    }
}
